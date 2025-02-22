// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// internal
import "../../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "../../utils/proxy/solidity-0.8.0/ProxyPausable.sol";
import "./GamesQueue.sol";

// interface
import "../../interfaces/ISportPositionalMarketManager.sol";
import "../../interfaces/ITherundownConsumerVerifier.sol";
import "../../interfaces/IGamesOddsObtainer.sol";
import "../../interfaces/ISportPositionalMarket.sol";
import "../../interfaces/IGamesPlayerProps.sol";

/// @title Consumer contract which stores all data from CL data feed (Link to docs: https://market.link/nodes/TheRundown/integrations), also creates all sports markets based on that data
/// @author gruja
contract TherundownConsumer is Initializable, ProxyOwned, ProxyPausable {
    /* ========== CONSTANTS =========== */

    uint public constant CANCELLED = 0;
    uint public constant HOME_WIN = 1;
    uint public constant AWAY_WIN = 2;
    uint public constant RESULT_DRAW = 3;
    uint public constant MIN_TAG_NUMBER = 9000;
    uint public constant STATUS_RETIRED = 201;

    /* ========== CONSUMER STATE VARIABLES ========== */

    struct GameCreate {
        bytes32 gameId;
        uint256 startTime;
        int24 homeOdds;
        int24 awayOdds;
        int24 drawOdds;
        string homeTeam;
        string awayTeam;
    }

    struct GameResolve {
        bytes32 gameId;
        uint8 homeScore;
        uint8 awayScore;
        uint8 statusId;
        uint40 lastUpdated;
    }

    struct GameOdds {
        bytes32 gameId;
        int24 homeOdds;
        int24 awayOdds;
        int24 drawOdds;
    }

    /* ========== STATE VARIABLES ========== */

    // global params
    address public wrapperAddress;
    mapping(address => bool) public whitelistedAddresses;

    // Maps <RequestId, Result>
    mapping(bytes32 => bytes[]) private requestIdGamesCreated; // deprecated see Wrapper
    mapping(bytes32 => bytes[]) private requestIdGamesResolved; // deprecated see Wrapper
    mapping(bytes32 => bytes[]) private requestIdGamesOdds; // deprecated see Wrapper

    // Maps <GameId, Game>
    mapping(bytes32 => GameCreate) public gameCreated;
    mapping(bytes32 => GameResolve) public gameResolved;
    mapping(bytes32 => GameOdds) private gameOdds; // deprecated see GamesOddsObtainer
    mapping(bytes32 => uint) public sportsIdPerGame;
    mapping(bytes32 => bool) public gameFulfilledCreated;
    mapping(bytes32 => bool) public gameFulfilledResolved;

    // sports props
    mapping(uint => bool) public supportedSport;
    mapping(uint => bool) public twoPositionSport;
    mapping(uint => bool) public supportResolveGameStatuses;
    mapping(uint => bool) public cancelGameStatuses;

    // market props
    ISportPositionalMarketManager public sportsManager;
    mapping(bytes32 => address) public marketPerGameId;
    mapping(address => bytes32) public gameIdPerMarket;
    mapping(address => bool) public marketResolved;
    mapping(address => bool) public marketCanceled;

    // game
    GamesQueue public queues;
    mapping(bytes32 => uint) private oddsLastPulledForGame; // deprecated see GamesOddsObtainer
    mapping(uint => bytes32[]) private gamesPerDate; // deprecated use gamesPerDatePerSport
    mapping(uint => mapping(uint => bool)) public isSportOnADate;
    mapping(address => bool) private invalidOdds; // deprecated see GamesOddsObtainer
    mapping(address => bool) public marketCreated;
    mapping(uint => mapping(uint => bytes32[])) public gamesPerDatePerSport;
    mapping(address => bool) public isPausedByCanceledStatus;
    mapping(address => bool) private canMarketBeUpdated; // deprecated
    mapping(bytes32 => uint) public gameOnADate;

    ITherundownConsumerVerifier public verifier;
    mapping(bytes32 => GameOdds) private backupOdds; // deprecated see GamesOddsObtainer
    IGamesOddsObtainer public oddsObtainer;
    uint public maxNumberOfMarketsToResolve;
    IGamesPlayerProps public playerProps;
    mapping(uint => bool) public ignoreChildCancellationPerSportIfDraw;
    uint public maxNumberOfMarketsToCreate;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _owner,
        uint[] memory _supportedSportIds,
        address _sportsManager,
        uint[] memory _twoPositionSports,
        GamesQueue _queues,
        uint[] memory _resolvedStatuses,
        uint[] memory _cancelGameStatuses
    ) external initializer {
        setOwner(_owner);

        for (uint i; i < _supportedSportIds.length; i++) {
            supportedSport[_supportedSportIds[i]] = true;
        }
        for (uint i; i < _twoPositionSports.length; i++) {
            twoPositionSport[_twoPositionSports[i]] = true;
        }
        for (uint i; i < _resolvedStatuses.length; i++) {
            supportResolveGameStatuses[_resolvedStatuses[i]] = true;
        }
        for (uint i; i < _cancelGameStatuses.length; i++) {
            cancelGameStatuses[_cancelGameStatuses[i]] = true;
        }

        sportsManager = ISportPositionalMarketManager(_sportsManager);
        queues = _queues;
        whitelistedAddresses[_owner] = true;
    }

    /* ========== CONSUMER FULFILL FUNCTIONS ========== */

    /// @notice fulfill all data necessary to create sport markets
    /// @param _requestId unique request id form CL
    /// @param _games array of a games that needed to be stored and transfered to markets
    /// @param _sportId sports id which is provided from CL (Example: NBA = 4)
    /// @param _date date on which game/games are played
    function fulfillGamesCreated(
        bytes32 _requestId,
        bytes[] memory _games,
        uint _sportId,
        uint _date
    ) external onlyWrapper {
        uint doubleChanceMultiplier = sportsManager.doesSportSupportDoubleChance(_sportId) ? 3 : 0;
        uint numOfMarkets = twoPositionSport[_sportId] ? _games.length : _games.length * (1 + doubleChanceMultiplier);

        if (_games.length > 0) {
            isSportOnADate[_date][_sportId] = true;
        }

        for (uint i = 0; i < _games.length; i++) {
            GameCreate memory gameForProcessing = abi.decode(_games[i], (GameCreate));
            // new game
            if (
                !gameFulfilledCreated[gameForProcessing.gameId] &&
                !verifier.isInvalidNames(gameForProcessing.homeTeam, gameForProcessing.awayTeam) &&
                gameForProcessing.startTime > block.timestamp
            ) {
                _updateGameOnADate(gameForProcessing.gameId, _date, _sportId);
                _createGameFulfill(_requestId, gameForProcessing, _sportId, numOfMarkets);
            }
            // old game UFC checking fighters
            else if (gameFulfilledCreated[gameForProcessing.gameId]) {
                GameCreate memory currentGameValues = getGameCreatedById(gameForProcessing.gameId);

                // if name (away or home) not the same
                if (
                    (!verifier.areTeamsEqual(gameForProcessing.homeTeam, currentGameValues.homeTeam) ||
                        !verifier.areTeamsEqual(gameForProcessing.awayTeam, currentGameValues.awayTeam))
                ) {
                    // double-check if market exists -> cancel market -> create new for queue
                    if (marketCreated[marketPerGameId[gameForProcessing.gameId]]) {
                        if (_sportId == 7) {
                            _cancelMarket(gameForProcessing.gameId, false);
                            _updateGameOnADate(gameForProcessing.gameId, _date, _sportId);
                            _createGameFulfill(_requestId, gameForProcessing, _sportId, numOfMarkets);
                        } else {
                            _pauseOrUnpauseMarket(marketPerGameId[gameForProcessing.gameId], true);
                            oddsObtainer.pauseUnpauseChildMarkets(marketPerGameId[gameForProcessing.gameId], true);
                            _pauseOrUnpausePlayerProps(marketPerGameId[gameForProcessing.gameId], true, false, false);
                        }
                    }
                    // checking time
                } else if (gameForProcessing.startTime != currentGameValues.startTime) {
                    _updateGameOnADate(gameForProcessing.gameId, _date, _sportId);
                    // if NEW start time is in future
                    if (gameForProcessing.startTime > block.timestamp) {
                        // this checks is for new markets
                        sportsManager.updateDatesForMarket(
                            marketPerGameId[gameForProcessing.gameId],
                            gameForProcessing.startTime
                        );
                        gameCreated[gameForProcessing.gameId] = gameForProcessing;
                    } else {
                        // double-check if market existst
                        if (
                            marketCreated[marketPerGameId[gameForProcessing.gameId]] &&
                            currentGameValues.startTime > block.timestamp
                        ) {
                            _pauseOrUnpauseMarket(marketPerGameId[gameForProcessing.gameId], true);
                            oddsObtainer.pauseUnpauseChildMarkets(marketPerGameId[gameForProcessing.gameId], true);
                            _pauseOrUnpausePlayerProps(marketPerGameId[gameForProcessing.gameId], true, false, false);
                            emit GameTimeMovedAhead(
                                marketPerGameId[gameForProcessing.gameId],
                                gameForProcessing.gameId,
                                currentGameValues.startTime,
                                gameForProcessing.startTime
                            );
                        }
                    }
                }
            }
        }
    }

    /// @notice fulfill all data necessary to resolve sport markets
    /// @param _requestId unique request id form CL
    /// @param _games array of a games that needed to be resolved
    /// @param _sportId sports id which is provided from CL (Example: NBA = 4)
    function fulfillGamesResolved(
        bytes32 _requestId,
        bytes[] memory _games,
        uint _sportId
    ) external onlyWrapper {
        uint numberOfMarketsToResolve = _games.length;
        for (uint i = 0; i < _games.length; i++) {
            GameResolve memory game = abi.decode(_games[i], (GameResolve));
            address _main = marketPerGameId[game.gameId];
            numberOfMarketsToResolve = numberOfMarketsToResolve + oddsObtainer.numberOfChildMarkets(_main);
        }
        for (uint i = 0; i < _games.length; i++) {
            GameResolve memory game = abi.decode(_games[i], (GameResolve));
            // if game is not resolved already and there is market for that game
            if (!gameFulfilledResolved[game.gameId] && marketPerGameId[game.gameId] != address(0)) {
                _resolveGameFulfill(_requestId, game, _sportId, numberOfMarketsToResolve);
            }
        }
    }

    /// @notice fulfill all data necessary to populate odds of a game
    /// @param _requestId unique request id form CL
    /// @param _games array of a games that needed to update the odds
    function fulfillGamesOdds(bytes32 _requestId, bytes[] memory _games) external onlyWrapper {
        for (uint i = 0; i < _games.length; i++) {
            IGamesOddsObtainer.GameOdds memory game = abi.decode(_games[i], (IGamesOddsObtainer.GameOdds));
            // game needs to be fulfilled and market needed to be created
            if (gameFulfilledCreated[game.gameId] && marketPerGameId[game.gameId] != address(0)) {
                oddsObtainer.obtainOdds(_requestId, game, sportsIdPerGame[game.gameId]);
            }
        }
    }

    /// @notice creates market for a given game id
    /// @param _gameId game id
    function createMarketForGame(bytes32 _gameId) public {
        require(
            marketPerGameId[_gameId] == address(0) ||
                (marketCanceled[marketPerGameId[_gameId]] && marketPerGameId[_gameId] != address(0)),
            "ID1"
        );
        require(gameFulfilledCreated[_gameId], "ID2");
        require(queues.gamesCreateQueue(queues.firstCreated()) == _gameId, "ID3");
        _createMarket(_gameId, true);
    }

    /// @notice creates markets for a given game ids
    /// @param _gameIds game ids as array
    function createAllMarketsForGames(bytes32[] memory _gameIds) external {
        for (uint i; i < _gameIds.length; i++) {
            createMarketForGame(_gameIds[i]);
        }
    }

    /// @notice resolve market for a given game id
    /// @param _gameId game id
    function resolveMarketForGame(bytes32 _gameId) public {
        require(!isGameResolvedOrCanceled(_gameId), "ID4");
        require(gameFulfilledResolved[_gameId], "ID5");
        _resolveMarket(_gameId, false);
    }

    /// @notice resolve all markets for a given game ids
    /// @param _gameIds game ids as array
    function resolveAllMarketsForGames(bytes32[] memory _gameIds) external {
        for (uint i; i < _gameIds.length; i++) {
            resolveMarketForGame(_gameIds[i]);
        }
    }

    /// @notice resolve market for a given market address
    /// @param _market market address
    /// @param _outcome outcome of a game (1: home win, 2: away win, 3: draw, 0: cancel market)
    /// @param _homeScore score of home team
    /// @param _awayScore score of away team
    function resolveMarketManually(
        address _market,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore,
        bool _useBackupOdds
    ) external isAddressWhitelisted canGameBeResolved(gameIdPerMarket[_market], _outcome, _homeScore, _awayScore) {
        _resolveMarketManually(_market, _outcome, _homeScore, _awayScore, _useBackupOdds);
    }

    /// @notice pause/unpause market for a given market address
    /// @param _market market address
    /// @param _pause pause = true, unpause = false
    function pauseOrUnpauseMarketManually(address _market, bool _pause) external isAddressWhitelisted {
        require(gameIdPerMarket[_market] != 0 && gameFulfilledCreated[gameIdPerMarket[_market]], "ID20");
        _pauseOrUnpauseMarketManually(_market, _pause);
    }

    /// @notice reopen game for processing the creation again
    /// @param gameId gameId
    function reopenGameForCreationProcessing(bytes32 gameId) external isAddressWhitelisted {
        require(gameFulfilledCreated[gameId], "ID22");
        gameFulfilledCreated[gameId] = false;
        gameFulfilledResolved[gameId] = false;
    }

    /// @notice setting isPausedByCanceledStatus from obtainer see @GamesOddsObtainer
    /// @param _market market address
    /// @param _flag flag true/false
    function setPausedByCanceledStatus(address _market, bool _flag) external canExecute {
        isPausedByCanceledStatus[_market] = _flag;
    }

    /// @notice pause market from obtainer see @GamesOddsObtainer
    /// @param _market market address
    /// @param _pause flag true/false
    function pauseOrUnpauseMarket(address _market, bool _pause) external canExecute {
        _pauseOrUnpauseMarket(_market, _pause);
    }

    /// @notice pause market from obtainer see @GamesOddsObtainer
    /// @param _main market address
    /// @param _pause flag true/false
    /// @param _invalidOdds flag true/false for invalid odds
    /// @param _circuitBreaker flag true/false for circuit breaker
    function pauseOrUnpauseMarketForPlayerProps(
        address _main,
        bool _pause,
        bool _invalidOdds,
        bool _circuitBreaker
    ) external canExecute {
        _pauseOrUnpausePlayerProps(_main, _pause, _invalidOdds, _circuitBreaker);
    }

    /// @notice setting gameid per market
    /// @param _gameId game id
    /// @param _child child market address
    function setGameIdPerChildMarket(bytes32 _gameId, address _child) external canExecute {
        gameIdPerMarket[_child] = _gameId;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice view function which returns game created object based on id of a game
    /// @param _gameId game id
    /// @return GameCreate game create object
    function getGameCreatedById(bytes32 _gameId) public view returns (GameCreate memory) {
        return gameCreated[_gameId];
    }

    /// @notice view function which returns game startTime
    /// @param _gameId game id
    function getGameStartTime(bytes32 _gameId) external view returns (uint256) {
        return gameCreated[_gameId].startTime;
    }

    /// @notice view function which returns lastUpdated from GameResolved struct
    /// @param _gameId game id
    function getLastUpdatedFromGameResolve(bytes32 _gameId) external view returns (uint40) {
        return gameResolved[_gameId].lastUpdated;
    }

    /// @notice view function which returns games on certan date and sportid
    /// @param _sportId date
    /// @param _date date
    /// @return bytes32[] list of games
    function getGamesPerDatePerSport(uint _sportId, uint _date) external view returns (bytes32[] memory) {
        return gamesPerDatePerSport[_sportId][_date];
    }

    /// @notice view function which returns props (sportid and game date)
    /// @param _market market address
    /// @return _sportId sport ids
    /// @return _gameDate game date on which game is playing
    function getGamePropsForOdds(address _market)
        external
        view
        returns (
            uint _sportId,
            uint _gameDate,
            bytes32 _id
        )
    {
        return (sportsIdPerGame[gameIdPerMarket[_market]], gameOnADate[gameIdPerMarket[_market]], gameIdPerMarket[_market]);
    }

    /// @notice view function which returns if game is resolved or canceled and ready for market to be resolved or canceled
    /// @param _gameId game id for which game is looking
    /// @return bool is it ready for resolve or cancel true/false
    function isGameResolvedOrCanceled(bytes32 _gameId) public view returns (bool) {
        return marketResolved[marketPerGameId[_gameId]] || marketCanceled[marketPerGameId[_gameId]];
    }

    /// @notice view function which returns if sport is two positional (no draw, example: NBA)
    /// @param _sportsId sport id for which is looking
    /// @return bool is sport two positional true/false
    function isSportTwoPositionsSport(uint _sportsId) public view returns (bool) {
        return twoPositionSport[_sportsId];
    }

    /// @notice view function which returns if market is child or not
    /// @param _market address of the checked market
    /// @return bool if the _market is child or not (true/false)
    function isChildMarket(address _market) public view returns (bool) {
        return oddsObtainer.childMarketMainMarket(_market) != address(0);
    }

    /// @notice view function which returns normalized odds up to 100 (Example: 50-40-10)
    /// @param _market market
    /// @return uint[] odds array normalized
    function getNormalizedOddsForMarket(address _market) external view returns (uint[] memory) {
        return marketCreated[_market] ? _getNormalizedOdds(gameIdPerMarket[_market]) : _getNormalizedChildOdds(_market);
    }

    /* ========== INTERNALS ========== */

    function _createGameFulfill(
        bytes32 requestId,
        GameCreate memory _game,
        uint _sportId,
        uint _numberOfGames
    ) internal {
        bool automaticCreation = _numberOfGames < maxNumberOfMarketsToCreate;
        gameCreated[_game.gameId] = _game;
        sportsIdPerGame[_game.gameId] = _sportId;
        if (!automaticCreation) {
            queues.enqueueGamesCreated(_game.gameId, _game.startTime, _sportId);
        }
        gameFulfilledCreated[_game.gameId] = true;
        oddsObtainer.setFirstOdds(_game.gameId, _game.homeOdds, _game.awayOdds, _game.drawOdds);

        emit GameCreated(requestId, _sportId, _game.gameId, _game, queues.lastCreated(), _getNormalizedOdds(_game.gameId));

        if (automaticCreation) {
            _createMarket(_game.gameId, false);
        }
    }

    function _resolveGameFulfill(
        bytes32 requestId,
        GameResolve memory _game,
        uint _sportId,
        uint _numberOfMarketsToResolve
    ) internal {
        GameCreate memory singleGameCreated = getGameCreatedById(_game.gameId);

        // if status is resolved OR (status is canceled AND start time has passed fulfill game to be resolved)
        if (
            _isGameStatusResolved(_game) ||
            (cancelGameStatuses[_game.statusId] && singleGameCreated.startTime < block.timestamp)
        ) {
            gameResolved[_game.gameId] = _game;
            gameFulfilledResolved[_game.gameId] = true;

            emit GameResolved(requestId, _sportId, _game.gameId, _game, queues.lastResolved());

            if (_numberOfMarketsToResolve >= maxNumberOfMarketsToResolve) {
                queues.enqueueGamesResolved(_game.gameId);
            } else {
                _resolveMarket(_game.gameId, true);
            }
        }
        // if status is canceled AND start time has not passed only pause market
        else if (cancelGameStatuses[_game.statusId] && singleGameCreated.startTime >= block.timestamp) {
            isPausedByCanceledStatus[marketPerGameId[_game.gameId]] = true;
            _pauseOrUnpauseMarket(marketPerGameId[_game.gameId], true);
            oddsObtainer.pauseUnpauseChildMarkets(marketPerGameId[_game.gameId], true);
            _pauseOrUnpausePlayerProps(marketPerGameId[_game.gameId], true, false, false);
        }
    }

    function _createMarket(bytes32 _gameId, bool _removeFromQueue) internal {
        GameCreate memory game = getGameCreatedById(_gameId);
        // only markets in a future, if not dequeue that creation
        if (game.startTime > block.timestamp) {
            uint[] memory tags = _calculateTags(sportsIdPerGame[_gameId]);

            // create
            ISportPositionalMarket market = sportsManager.createMarket(
                _gameId,
                string(abi.encodePacked(game.homeTeam, " vs ", game.awayTeam)), // gameLabel
                game.startTime, //maturity
                0, //initialMint
                twoPositionSport[sportsIdPerGame[_gameId]] ? 2 : 3,
                tags, //tags
                false,
                address(0)
            );

            marketPerGameId[game.gameId] = address(market);
            gameIdPerMarket[address(market)] = game.gameId;
            marketCreated[address(market)] = true;

            oddsObtainer.setFirstNormalizedOdds(game.gameId, address(market));

            if (_removeFromQueue) {
                queues.dequeueGamesCreated();
            }
            emit CreateSportsMarket(address(market), game.gameId, game, tags, _getNormalizedOdds(game.gameId));
        } else {
            if (_removeFromQueue) {
                queues.dequeueGamesCreated();
            }
        }
    }

    function _resolveMarket(bytes32 _gameId, bool _resolveMarketWithoutQueue) internal {
        GameResolve memory game = gameResolved[_gameId];
        GameCreate memory singleGameCreated = getGameCreatedById(_gameId);

        if (_isGameStatusResolved(game)) {
            if (oddsObtainer.invalidOdds(marketPerGameId[game.gameId])) {
                _pauseOrUnpauseMarket(marketPerGameId[game.gameId], false);
                oddsObtainer.pauseUnpauseChildMarkets(marketPerGameId[game.gameId], false);
                _pauseOrUnpausePlayerProps(marketPerGameId[game.gameId], false, false, false);
            }

            (uint _outcome, uint8 _homeScore, uint8 _awayScore) = _calculateOutcome(game);

            // if result is draw and game is two positional
            if (_outcome == RESULT_DRAW && twoPositionSport[sportsIdPerGame[game.gameId]]) {
                if (ignoreChildCancellationPerSportIfDraw[sportsIdPerGame[game.gameId]]) {
                    _cancelMainResolveChild(
                        marketPerGameId[game.gameId],
                        _outcome,
                        _homeScore,
                        _awayScore,
                        !_resolveMarketWithoutQueue
                    );
                } else {
                    _cancelMarket(game.gameId, !_resolveMarketWithoutQueue);
                }
            } else {
                // if market is paused only remove from queue
                if (!sportsManager.isMarketPaused(marketPerGameId[game.gameId])) {
                    _setMarketCancelOrResolved(
                        marketPerGameId[game.gameId],
                        _outcome,
                        _homeScore,
                        _awayScore,
                        game.statusId
                    );
                    if (!_resolveMarketWithoutQueue) {
                        _cleanStorageQueue();
                    }

                    emit ResolveSportsMarket(marketPerGameId[game.gameId], game.gameId, _outcome);
                } else {
                    if (!_resolveMarketWithoutQueue) {
                        _cleanStorageQueue();
                    }
                }
            }
            // if status is canceled and start time of a game passed cancel market
        } else if (cancelGameStatuses[game.statusId] && singleGameCreated.startTime < block.timestamp) {
            _cancelMarket(game.gameId, !_resolveMarketWithoutQueue);
        }
    }

    function _resolveMarketManually(
        address _market,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore,
        bool _useBackupOdds
    ) internal {
        if (_useBackupOdds) {
            require(_outcome == CANCELLED, "ID17");
            require(oddsObtainer.areOddsValid(gameIdPerMarket[_market], _useBackupOdds));
            oddsObtainer.setBackupOddsAsMainOddsForGame(gameIdPerMarket[_market]);
        }

        _pauseOrUnpauseMarket(_market, false);
        oddsObtainer.pauseUnpauseChildMarkets(_market, false);
        _pauseOrUnpausePlayerProps(_market, false, false, false);
        _setMarketCancelOrResolved(
            _market,
            _outcome,
            _homeScore,
            _awayScore,
            twoPositionSport[sportsIdPerGame[gameIdPerMarket[_market]]] ? 8 : 11
        );
        gameResolved[gameIdPerMarket[_market]] = GameResolve(
            gameIdPerMarket[_market],
            _homeScore,
            _awayScore,
            twoPositionSport[sportsIdPerGame[gameIdPerMarket[_market]]] ? 8 : 11,
            0
        );

        emit GameResolved(
            gameIdPerMarket[_market], // no req. from CL (manual resolve) so just put gameID
            sportsIdPerGame[gameIdPerMarket[_market]],
            gameIdPerMarket[_market],
            gameResolved[gameIdPerMarket[_market]],
            0
        );

        if (_outcome == CANCELLED) {
            emit CancelSportsMarket(_market, gameIdPerMarket[_market]);
        } else {
            emit ResolveSportsMarket(_market, gameIdPerMarket[_market], _outcome);
        }
    }

    function _pauseOrUnpauseMarketManually(address _market, bool _pause) internal {
        _pauseOrUnpauseMarket(_market, _pause);
        oddsObtainer.pauseUnpauseCurrentActiveChildMarket(gameIdPerMarket[_market], _market, _pause);
    }

    function _pauseOrUnpausePlayerProps(
        address _market,
        bool _pause,
        bool _invalidOdds,
        bool _circuitBreaker
    ) internal {
        playerProps.pauseAllPlayerPropsMarketForMain(_market, _pause, _invalidOdds, _circuitBreaker);
    }

    function _pauseOrUnpauseMarket(address _market, bool _pause) internal {
        if (sportsManager.isMarketPaused(_market) != _pause) {
            sportsManager.setMarketPaused(_market, _pause);
            emit PauseSportsMarket(_market, _pause);
        }
    }

    function _cancelMarket(bytes32 _gameId, bool cleanStorage) internal {
        _setMarketCancelOrResolved(marketPerGameId[_gameId], CANCELLED, 0, 0, 0);
        if (cleanStorage) {
            _cleanStorageQueue();
        }

        emit CancelSportsMarket(marketPerGameId[_gameId], _gameId);
    }

    function _setMarketCancelOrResolved(
        address _market,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore,
        uint8 _status
    ) internal {
        sportsManager.resolveMarket(_market, _outcome);
        if (_status == STATUS_RETIRED) {
            oddsObtainer.resolveChildMarkets(_market, 0, 0, 0);
        } else {
            oddsObtainer.resolveChildMarkets(_market, _outcome, _homeScore, _awayScore);
            if (_outcome == CANCELLED) {
                playerProps.cancelPlayerPropsMarketForMain(_market);
            }
        }
        marketCanceled[_market] = _outcome == CANCELLED;
        marketResolved[_market] = _outcome != CANCELLED;
    }

    function _cancelMainResolveChild(
        address _market,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore,
        bool _cleanStorage
    ) internal {
        sportsManager.resolveMarket(_market, 0); // cancel main
        oddsObtainer.resolveChildMarkets(_market, _outcome, _homeScore, _awayScore);
        marketCanceled[_market] = false;
        marketResolved[_market] = true; // must be true because of player props resolve
        if (_cleanStorage) {
            _cleanStorageQueue();
        }
        emit CancelSportsMarket(_market, gameIdPerMarket[_market]);
    }

    function _cleanStorageQueue() internal {
        queues.dequeueGamesResolved();
    }

    function _calculateTags(uint _sportsId) internal pure returns (uint[] memory) {
        uint[] memory result = new uint[](1);
        result[0] = MIN_TAG_NUMBER + _sportsId;
        return result;
    }

    function _isGameStatusResolved(GameResolve memory _game) internal view returns (bool) {
        return supportResolveGameStatuses[_game.statusId];
    }

    function _calculateOutcome(GameResolve memory _game)
        internal
        pure
        returns (
            uint,
            uint8,
            uint8
        )
    {
        if (_game.homeScore == _game.awayScore) {
            return (RESULT_DRAW, _game.homeScore, _game.awayScore);
        }
        return
            _game.homeScore > _game.awayScore
                ? (HOME_WIN, _game.homeScore, _game.awayScore)
                : (AWAY_WIN, _game.homeScore, _game.awayScore);
    }

    function _updateGameOnADate(
        bytes32 _gameId,
        uint _date,
        uint _sportId
    ) internal {
        if (gameOnADate[_gameId] != _date) {
            gamesPerDatePerSport[_sportId][_date].push(_gameId);
            gameOnADate[_gameId] = _date;
        }
    }

    function _getNormalizedOdds(bytes32 _gameId) internal view returns (uint[] memory) {
        return oddsObtainer.getNormalizedOdds(_gameId);
    }

    function _getNormalizedChildOdds(address _market) internal view returns (uint[] memory) {
        return
            oddsObtainer.childMarketCreated(_market)
                ? oddsObtainer.getNormalizedOddsForMarket(_market)
                : playerProps.getNormalizedOddsForMarket(_market);
    }

    /* ========== CONTRACT MANAGEMENT ========== */

    /// @notice sets if sport is suported or not (delete from supported sport)
    /// @param _sportId sport id which needs to be supported or not
    /// @param _isSupported true/false (supported or not)
    function setSupportedSport(uint _sportId, bool _isSupported) external onlyOwner {
        require(supportedSport[_sportId] != _isSupported);
        supportedSport[_sportId] = _isSupported;
        emit SupportedSportsChanged(_sportId, _isSupported);
    }

    /// @notice sets resolved status which is supported or not
    /// @param _status status ID which needs to be supported or not
    /// @param _isSupported true/false (supported or not)
    function setSupportedResolvedStatuses(uint _status, bool _isSupported) external onlyOwner {
        require(supportResolveGameStatuses[_status] != _isSupported);
        supportResolveGameStatuses[_status] = _isSupported;
        emit SupportedResolvedStatusChanged(_status, _isSupported);
    }

    /// @notice sets cancel status which is supported or not
    /// @param _status ststus ID which needs to be supported or not
    /// @param _isSupported true/false (supported or not)
    function setSupportedCancelStatuses(uint _status, bool _isSupported) external onlyOwner {
        require(cancelGameStatuses[_status] != _isSupported);
        cancelGameStatuses[_status] = _isSupported;
        emit SupportedCancelStatusChanged(_status, _isSupported);
    }

    /// @notice sets ignoring children cancelation
    /// @param _sportId sport if
    /// @param _flag true/false
    function setIgnoreChildCancellationPerSportIfDraw(uint _sportId, bool _flag) external onlyOwner {
        ignoreChildCancellationPerSportIfDraw[_sportId] = _flag;
        emit IgnoreChildCancellationPerSportIfDraw(_sportId, _flag);
    }

    /// @notice sets if sport is two positional (Example: NBA)
    /// @param _sportId sport ID which is two positional
    /// @param _isTwoPosition true/false (two positional sport or not)
    function setTwoPositionSport(uint _sportId, bool _isTwoPosition) external onlyOwner {
        require(supportedSport[_sportId] && twoPositionSport[_sportId] != _isTwoPosition);
        twoPositionSport[_sportId] = _isTwoPosition;
        emit TwoPositionSportChanged(_sportId, _isTwoPosition);
    }

    /// @notice sets how many markets (main + children) are processed without queue
    /// @param _maxNumberOfMarketsToResolve max number of markets for automatic resolve w/o queue entering
    function setNewMaxNumberOfMarketsToResolveAndResolve(uint _maxNumberOfMarketsToResolve, uint _maxNumberOfMarketsToCreate)
        external
        onlyOwner
    {
        require(
            maxNumberOfMarketsToResolve != _maxNumberOfMarketsToResolve ||
                maxNumberOfMarketsToCreate != _maxNumberOfMarketsToCreate
        );
        maxNumberOfMarketsToResolve = _maxNumberOfMarketsToResolve;
        maxNumberOfMarketsToCreate = _maxNumberOfMarketsToCreate;
        emit NewMaxNumberOfMarketsToResolveAndCreate(_maxNumberOfMarketsToResolve, _maxNumberOfMarketsToCreate);
    }

    /// @notice sets wrapper, manager, queue  address
    /// @param _wrapperAddress wrapper address
    /// @param _queues queue address
    /// @param _sportsManager sport manager address
    function setSportContracts(
        address _wrapperAddress,
        GamesQueue _queues,
        address _sportsManager,
        address _verifier,
        address _oddsObtainer,
        address _playerProps
    ) external onlyOwner {
        sportsManager = ISportPositionalMarketManager(_sportsManager);
        queues = _queues;
        wrapperAddress = _wrapperAddress;
        verifier = ITherundownConsumerVerifier(_verifier);
        oddsObtainer = IGamesOddsObtainer(_oddsObtainer);
        playerProps = IGamesPlayerProps(_playerProps);

        emit NewSportContracts(_wrapperAddress, _queues, _sportsManager, _verifier, _oddsObtainer, _playerProps);
    }

    /// @notice adding/removing whitelist address depending on a flag
    /// @param _whitelistAddress address that needed to be whitelisted/ ore removed from WL
    /// @param _flag adding or removing from whitelist (true: add, false: remove)
    function addToWhitelist(address _whitelistAddress, bool _flag) external onlyOwner {
        require(_whitelistAddress != address(0) && whitelistedAddresses[_whitelistAddress] != _flag);
        whitelistedAddresses[_whitelistAddress] = _flag;
        emit AddedIntoWhitelist(_whitelistAddress, _flag);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyWrapper() {
        require(msg.sender == wrapperAddress, "ID9");
        _;
    }

    modifier canExecute() {
        require(msg.sender == address(oddsObtainer) || msg.sender == address(playerProps), "ID18");
        _;
    }

    modifier isAddressWhitelisted() {
        require(whitelistedAddresses[msg.sender], "ID10");
        _;
    }

    modifier canGameBeResolved(
        bytes32 _gameId,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore
    ) {
        require(!isGameResolvedOrCanceled(_gameId), "ID13");
        require(marketPerGameId[_gameId] != address(0), "ID14");
        require(
            verifier.isValidOutcomeForGame(twoPositionSport[sportsIdPerGame[_gameId]], _outcome) &&
                verifier.isValidOutcomeWithResult(_outcome, _homeScore, _awayScore),
            "ID15"
        );
        _;
    }
    /* ========== EVENTS ========== */

    event GameCreated(
        bytes32 _requestId,
        uint _sportId,
        bytes32 _id,
        GameCreate _game,
        uint _queueIndex,
        uint[] _normalizedOdds
    );
    event GameResolved(bytes32 _requestId, uint _sportId, bytes32 _id, GameResolve _game, uint _queueIndex);
    event CreateSportsMarket(address _marketAddress, bytes32 _id, GameCreate _game, uint[] _tags, uint[] _normalizedOdds);
    event ResolveSportsMarket(address _marketAddress, bytes32 _id, uint _outcome);
    event PauseSportsMarket(address _marketAddress, bool _pause);
    event CancelSportsMarket(address _marketAddress, bytes32 _id);
    event SupportedSportsChanged(uint _sportId, bool _isSupported);
    event SupportedResolvedStatusChanged(uint _status, bool _isSupported);
    event SupportedCancelStatusChanged(uint _status, bool _isSupported);
    event TwoPositionSportChanged(uint _sportId, bool _isTwoPosition);
    event NewSportContracts(
        address _wrapperAddress,
        GamesQueue _queues,
        address _sportsManager,
        address _verifier,
        address _oddsObtainer,
        address _playerProps
    );
    event AddedIntoWhitelist(address _whitelistAddress, bool _flag);
    event NewMaxNumberOfMarketsToResolveAndCreate(uint _maxNumberResolve, uint _maxNumberCreate);
    event GameTimeMovedAhead(address _market, bytes32 _gameId, uint _oldStartTime, uint _newStartTime);
    event IgnoreChildCancellationPerSportIfDraw(uint _sportId, bool _flag);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Clone of syntetix contract without constructor
contract ProxyOwned {
    address public owner;
    address public nominatedOwner;
    bool private _initialized;
    bool private _transferredAtInit;

    function setOwner(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        require(!_initialized, "Already initialized, use nominateNewOwner");
        _initialized = true;
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    function transferOwnershipAtInit(address proxyAddress) external onlyOwner {
        require(proxyAddress != address(0), "Invalid address");
        require(!_transferredAtInit, "Already transferred");
        owner = proxyAddress;
        _transferredAtInit = true;
        emit OwnerChanged(owner, proxyAddress);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Inheritance
import "./ProxyOwned.sol";

// Clone of syntetix contract without constructor

contract ProxyPausable is ProxyOwned {
    uint public lastPauseTime;
    bool public paused;

    

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = block.timestamp;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// internal
import "../../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "../../utils/proxy/solidity-0.8.0/ProxyPausable.sol";

/// @title Storage for games (created or resolved), calculation for order-making bot processing
/// @author gruja
contract GamesQueue is Initializable, ProxyOwned, ProxyPausable {
    // create games queue
    mapping(uint => bytes32) public gamesCreateQueue;
    mapping(bytes32 => bool) public existingGamesInCreatedQueue;
    uint public firstCreated;
    uint public lastCreated;
    mapping(bytes32 => uint) private gameStartPerGameId;

    // resolve games queue
    bytes32[] public unproccessedGames;
    mapping(bytes32 => uint) public unproccessedGamesIndex;
    mapping(uint => bytes32) public gamesResolvedQueue;
    mapping(bytes32 => bool) public existingGamesInResolvedQueue;
    uint public firstResolved;
    uint public lastResolved;

    address public consumer;
    mapping(address => bool) public whitelistedAddresses;

    /// @notice public initialize proxy method
    /// @param _owner future owner of a contract
    function initialize(address _owner) public initializer {
        setOwner(_owner);
        firstCreated = 1;
        lastCreated = 0;
        firstResolved = 1;
        lastResolved = 0;
    }

    /// @notice putting game in a crated queue and fill up unprocessed games array
    /// @param data id of a game in byte32
    /// @param startTime game start time
    /// @param sportsId id of a sport (Example: NBA = 4 etc.)
    function enqueueGamesCreated(
        bytes32 data,
        uint startTime,
        uint sportsId
    ) public canExecuteFunction {
        lastCreated += 1;
        gamesCreateQueue[lastCreated] = data;

        existingGamesInCreatedQueue[data] = true;

        emit EnqueueGamesCreated(data, sportsId, lastCreated);
    }

    /// @notice removing first game in a queue from created queue
    /// @return data returns id of a game which is removed
    function dequeueGamesCreated() public canExecuteFunction returns (bytes32 data) {
        require(lastCreated >= firstCreated, "No more elements in a queue");

        data = gamesCreateQueue[firstCreated];

        delete gamesCreateQueue[firstCreated];
        firstCreated += 1;

        emit DequeueGamesCreated(data, firstResolved - 1);
    }

    /// @notice putting game in a resolved queue
    /// @param data id of a game in byte32
    function enqueueGamesResolved(bytes32 data) public canExecuteFunction {
        lastResolved += 1;
        gamesResolvedQueue[lastResolved] = data;
        existingGamesInResolvedQueue[data] = true;

        emit EnqueueGamesResolved(data, lastCreated);
    }

    /// @notice removing first game in a queue from resolved queue
    /// @return data returns id of a game which is removed
    function dequeueGamesResolved() public canExecuteFunction returns (bytes32 data) {
        require(lastResolved >= firstResolved, "No more elements in a queue");

        data = gamesResolvedQueue[firstResolved];

        delete gamesResolvedQueue[firstResolved];
        firstResolved += 1;

        emit DequeueGamesResolved(data, firstResolved - 1);
    }

    /// @notice sets the consumer contract address, which only owner can execute
    /// @param _consumer address of a consumer contract
    function setConsumerAddress(address _consumer) external onlyOwner {
        require(_consumer != address(0), "Invalid address");
        consumer = _consumer;
        emit NewConsumerAddress(_consumer);
    }

    /// @notice adding/removing whitelist address depending on a flag
    /// @param _whitelistAddress address that needed to be whitelisted/ ore removed from WL
    /// @param _flag adding or removing from whitelist (true: add, false: remove)
    function addToWhitelist(address _whitelistAddress, bool _flag) external onlyOwner {
        require(_whitelistAddress != address(0) && whitelistedAddresses[_whitelistAddress] != _flag, "Invalid");
        whitelistedAddresses[_whitelistAddress] = _flag;
        emit AddedIntoWhitelist(_whitelistAddress, _flag);
    }

    modifier canExecuteFunction() {
        require(msg.sender == consumer || whitelistedAddresses[msg.sender], "Only consumer or whitelisted address");
        _;
    }

    event EnqueueGamesCreated(bytes32 _gameId, uint _sportId, uint _index);
    event EnqueueGamesResolved(bytes32 _gameId, uint _index);
    event DequeueGamesCreated(bytes32 _gameId, uint _index);
    event DequeueGamesResolved(bytes32 _gameId, uint _index);
    event NewConsumerAddress(address _consumer);
    event AddedIntoWhitelist(address _whitelistAddress, bool _flag);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISportPositionalMarket.sol";

interface ISportPositionalMarketManager {
    /* ========== VIEWS / VARIABLES ========== */

    function marketCreationEnabled() external view returns (bool);

    function totalDeposited() external view returns (uint);

    function numActiveMarkets() external view returns (uint);

    function activeMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function numMaturedMarkets() external view returns (uint);

    function maturedMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function isActiveMarket(address candidate) external view returns (bool);

    function isDoubleChanceMarket(address candidate) external view returns (bool);

    function doesSportSupportDoubleChance(uint _sport) external view returns (bool);

    function isDoubleChanceSupported() external view returns (bool);

    function isKnownMarket(address candidate) external view returns (bool);

    function getActiveMarketAddress(uint _index) external view returns (address);

    function transformCollateral(uint value) external view returns (uint);

    function reverseTransformCollateral(uint value) external view returns (uint);

    function isMarketPaused(address _market) external view returns (bool);

    function expiryDuration() external view returns (uint);

    function isWhitelistedAddress(address _address) external view returns (bool);

    function getOddsObtainer() external view returns (address obtainer);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createMarket(
        bytes32 gameId,
        string memory gameLabel,
        uint maturity,
        uint initialMint, // initial sUSD to mint options for,
        uint positionCount,
        uint[] memory tags,
        bool isChild,
        address parentMarket
    ) external returns (ISportPositionalMarket);

    function setMarketPaused(address _market, bool _paused) external;

    function updateDatesForMarket(address _market, uint256 _newStartTime) external;

    function resolveMarket(address market, uint outcome) external;

    function expireMarkets(address[] calldata market) external;

    function transferSusdTo(
        address sender,
        address receiver,
        uint amount
    ) external;

    function queryMintsAndMaturityStatusForPlayerProps(address[] memory _playerPropsMarkets)
        external
        view
        returns (
            bool[] memory _hasAnyMintsArray,
            bool[] memory _isMaturedArray,
            bool[] memory _isResolvedArray,
            uint[] memory _maturities
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITherundownConsumerVerifier {
    // view functions
    function isInvalidNames(string memory _teamA, string memory _teamB) external view returns (bool);

    function areTeamsEqual(string memory _teamA, string memory _teamB) external view returns (bool);

    function isSupportedMarketType(string memory _market) external view returns (bool);

    function areOddsArrayInThreshold(
        uint _sportId,
        uint[] memory _currentOddsArray,
        uint[] memory _newOddsArray,
        bool _isTwoPositionalSport
    ) external view returns (bool);

    function areOddsValid(
        bool _isTwoPositionalSport,
        int24 _homeOdds,
        int24 _awayOdds,
        int24 _drawOdds
    ) external view returns (bool);

    function areSpreadOddsValid(
        int16 spreadHome,
        int24 spreadHomeOdds,
        int16 spreadAway,
        int24 spreadAwayOdds
    ) external view returns (bool);

    function areTotalOddsValid(
        uint24 totalOver,
        int24 totalOverOdds,
        uint24 totalUnder,
        int24 totalUnderOdds
    ) external view returns (bool);

    function areOddsAndLinesValidForPlayer(
        uint16 _line,
        int24 _overOdds,
        int24 _underOdds
    ) external pure returns (bool);

    function isValidOutcomeForGame(bool _isTwoPositionalSport, uint _outcome) external view returns (bool);

    function isValidOutcomeWithResult(
        uint _outcome,
        uint _homeScore,
        uint _awayScore
    ) external view returns (bool);

    function calculateAndNormalizeOdds(int[] memory _americanOdds) external view returns (uint[] memory);

    function getBookmakerIdsBySportId(uint256 _sportId) external view returns (uint256[] memory);

    function getBookmakerIdsBySportIdForPlayerProps(uint256 _sportId) external view returns (uint256[] memory);

    function getStringIDsFromBytesArrayIDs(bytes32[] memory _ids) external view returns (string[] memory);

    function convertUintToString(uint8[] memory _options) external view returns (string[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGamesOddsObtainer {
    struct GameOdds {
        bytes32 gameId;
        int24 homeOdds;
        int24 awayOdds;
        int24 drawOdds;
        int16 spreadHome;
        int24 spreadHomeOdds;
        int16 spreadAway;
        int24 spreadAwayOdds;
        uint24 totalOver;
        int24 totalOverOdds;
        uint24 totalUnder;
        int24 totalUnderOdds;
    }

    // view

    function getActiveChildMarketsFromParent(address _parent) external view returns (address, address);

    function getSpreadTotalsChildMarketsFromParent(address _parent)
        external
        view
        returns (
            uint numOfSpreadMarkets,
            address[] memory spreadMarkets,
            uint numOfTotalsMarkets,
            address[] memory totalMarkets
        );

    function areOddsValid(bytes32 _gameId, bool _useBackup) external view returns (bool);

    function invalidOdds(address _market) external view returns (bool);

    function getNormalizedOdds(bytes32 _gameId) external view returns (uint[] memory);

    function getNormalizedOddsForMarket(address _market) external view returns (uint[] memory);

    function getOddsForGames(bytes32[] memory _gameIds) external view returns (int24[] memory odds);

    function mainMarketChildMarketIndex(address _main, uint _index) external view returns (address);

    function numberOfChildMarkets(address _main) external view returns (uint);

    function mainMarketSpreadChildMarket(address _main, int16 _spread) external view returns (address);

    function mainMarketTotalChildMarket(address _main, uint24 _total) external view returns (address);

    function childMarketMainMarket(address _market) external view returns (address);

    function childMarketTotal(address _market) external view returns (uint24);

    function currentActiveTotalChildMarket(address _main) external view returns (address);

    function currentActiveSpreadChildMarket(address _main) external view returns (address);

    function isSpreadChildMarket(address _child) external view returns (bool);

    function childMarketCreated(address _child) external view returns (bool);

    function getOddsForGame(bytes32 _gameId)
        external
        view
        returns (
            int24,
            int24,
            int24,
            int24,
            int24,
            int24,
            int24
        );

    function getLinesForGame(bytes32 _gameId)
        external
        view
        returns (
            int16,
            int16,
            uint24,
            uint24
        );

    // executable

    function obtainOdds(
        bytes32 requestId,
        GameOdds memory _game,
        uint _sportId
    ) external;

    function setFirstOdds(
        bytes32 _gameId,
        int24 _homeOdds,
        int24 _awayOdds,
        int24 _drawOdds
    ) external;

    function setFirstNormalizedOdds(bytes32 _gameId, address _market) external;

    function setBackupOddsAsMainOddsForGame(bytes32 _gameId) external;

    function pauseUnpauseChildMarkets(address _main, bool _flag) external;

    function pauseUnpauseCurrentActiveChildMarket(
        bytes32 _gameId,
        address _main,
        bool _flag
    ) external;

    function resolveChildMarkets(
        address _market,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore
    ) external;

    function setChildMarketGameId(bytes32 gameId, address market) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

import "../interfaces/IPositionalMarketManager.sol";
import "../interfaces/IPosition.sol";
import "../interfaces/IPriceFeed.sol";

interface ISportPositionalMarket {
    /* ========== TYPES ========== */

    enum Phase {
        Trading,
        Maturity,
        Expiry
    }
    enum Side {
        Cancelled,
        Home,
        Away,
        Draw
    }

    /* ========== VIEWS / VARIABLES ========== */

    function getOptions()
        external
        view
        returns (
            IPosition home,
            IPosition away,
            IPosition draw
        );

    function times() external view returns (uint maturity, uint destruction);

    function initialMint() external view returns (uint);

    function getGameDetails() external view returns (bytes32 gameId, string memory gameLabel);

    function getGameId() external view returns (bytes32);

    function deposited() external view returns (uint);

    function optionsCount() external view returns (uint);

    function creator() external view returns (address);

    function resolved() external view returns (bool);

    function cancelled() external view returns (bool);

    function paused() external view returns (bool);

    function phase() external view returns (Phase);

    function canResolve() external view returns (bool);

    function result() external view returns (Side);

    function isChild() external view returns (bool);

    function tags(uint idx) external view returns (uint);

    function getTags() external view returns (uint tag1, uint tag2);

    function getTagsLength() external view returns (uint tagsLength);

    function getParentMarketPositions() external view returns (IPosition position1, IPosition position2);

    function getStampedOdds()
        external
        view
        returns (
            uint,
            uint,
            uint
        );

    function balancesOf(address account)
        external
        view
        returns (
            uint home,
            uint away,
            uint draw
        );

    function totalSupplies()
        external
        view
        returns (
            uint home,
            uint away,
            uint draw
        );

    function isDoubleChance() external view returns (bool);

    function parentMarket() external view returns (ISportPositionalMarket);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setPaused(bool _paused) external;

    function updateDates(uint256 _maturity, uint256 _expiry) external;

    function mint(uint value) external;

    function exerciseOptions() external;

    function restoreInvalidOdds(
        uint _homeOdds,
        uint _awayOdds,
        uint _drawOdds
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGamesPlayerProps {
    struct PlayerProps {
        bytes32 gameId;
        bytes32 playerId;
        uint8 option;
        string playerName;
        uint16 line;
        int24 overOdds;
        int24 underOdds;
    }

    struct PlayerPropsResolver {
        bytes32 gameId;
        bytes32 playerId;
        uint8 option;
        uint16 score;
        uint8 statusId;
    }

    function obtainPlayerProps(PlayerProps memory _player, uint _sportId) external;

    function resolvePlayerProps(PlayerPropsResolver memory _result) external;

    function cancelMarketFromManager(address _market) external;

    function pauseAllPlayerPropsMarketForMain(
        address _main,
        bool _flag,
        bool _invalidOddsOnMain,
        bool _circuitBreakerMain
    ) external;

    function createFulfilledForPlayerProps(
        bytes32 gameId,
        bytes32 playerId,
        uint8 option
    ) external view returns (bool);

    function cancelPlayerPropsMarketForMain(address _main) external;

    function getNormalizedOddsForMarket(address _market) external view returns (uint[] memory);

    function mainMarketChildMarketIndex(address _main, uint _index) external view returns (address);

    function numberOfChildMarkets(address _main) external view returns (uint);

    function doesSportSupportPlayerProps(uint _sportId) external view returns (bool);

    function pausedByInvalidOddsOnMain(address _main) external view returns (bool);

    function pausedByCircuitBreakerOnMain(address _main) external view returns (bool);

    function playerIdPerChildMarket(address _market) external view returns (bytes32);

    function optionIdPerChildMarket(address _market) external view returns (uint8);

    function getAllOptionsWithPlayersForGameId(bytes32 _gameId)
        external
        view
        returns (
            bytes32[] memory _playerIds,
            uint8[] memory _options,
            bool[] memory _isResolved,
            address[][] memory _childMarketsPerOption
        );

    function getPlayerPropsDataForMarket(address _market)
        external
        view
        returns (
            address,
            bytes32,
            bytes32,
            uint8
        );

    function getPlayerPropForOption(
        bytes32 gameId,
        bytes32 playerId,
        uint8 option
    )
        external
        view
        returns (
            uint16,
            int24,
            int24,
            bool
        );

    function fulfillPlayerPropsCLResolved(bytes[] memory _playerProps) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "../interfaces/IPositionalMarket.sol";

interface IPositionalMarketManager {
    /* ========== VIEWS / VARIABLES ========== */

    function durations() external view returns (uint expiryDuration, uint maxTimeToMaturity);

    function capitalRequirement() external view returns (uint);

    function marketCreationEnabled() external view returns (bool);

    function onlyAMMMintingAndBurning() external view returns (bool);

    function transformCollateral(uint value) external view returns (uint);

    function reverseTransformCollateral(uint value) external view returns (uint);

    function totalDeposited() external view returns (uint);

    function numActiveMarkets() external view returns (uint);

    function activeMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function numMaturedMarkets() external view returns (uint);

    function maturedMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function isActiveMarket(address candidate) external view returns (bool);

    function isKnownMarket(address candidate) external view returns (bool);

    function getThalesAMM() external view returns (address);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createMarket(
        bytes32 oracleKey,
        uint strikePrice,
        uint maturity,
        uint initialMint // initial sUSD to mint options for,
    ) external returns (IPositionalMarket);

    function resolveMarket(address market) external;

    function expireMarkets(address[] calldata market) external;

    function transferSusdTo(
        address sender,
        address receiver,
        uint amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "./IPositionalMarket.sol";

interface IPosition {
    /* ========== VIEWS / VARIABLES ========== */

    function getBalanceOf(address account) external view returns (uint);

    function getTotalSupply() external view returns (uint);

    function exerciseWithAmount(address claimant, uint amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

interface IPriceFeed {
    // Structs
    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }

    // Mutative functions
    function addAggregator(bytes32 currencyKey, address aggregatorAddress) external;

    function removeAggregator(bytes32 currencyKey) external;

    // Views

    function rateForCurrency(bytes32 currencyKey) external view returns (uint);

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint rate, uint time);

    function getRates() external view returns (uint[] memory);

    function getCurrencies() external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "../interfaces/IPositionalMarketManager.sol";
import "../interfaces/IPosition.sol";
import "../interfaces/IPriceFeed.sol";

interface IPositionalMarket {
    /* ========== TYPES ========== */

    enum Phase {
        Trading,
        Maturity,
        Expiry
    }
    enum Side {
        Up,
        Down
    }

    /* ========== VIEWS / VARIABLES ========== */

    function getOptions() external view returns (IPosition up, IPosition down);

    function times() external view returns (uint maturity, uint destructino);

    function getOracleDetails()
        external
        view
        returns (
            bytes32 key,
            uint strikePrice,
            uint finalPrice
        );

    function fees() external view returns (uint poolFee, uint creatorFee);

    function deposited() external view returns (uint);

    function creator() external view returns (address);

    function resolved() external view returns (bool);

    function phase() external view returns (Phase);

    function oraclePrice() external view returns (uint);

    function oraclePriceAndTimestamp() external view returns (uint price, uint updatedAt);

    function canResolve() external view returns (bool);

    function result() external view returns (Side);

    function balancesOf(address account) external view returns (uint up, uint down);

    function totalSupplies() external view returns (uint up, uint down);

    function getMaximumBurnable(address account) external view returns (uint amount);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function mint(uint value) external;

    function exerciseOptions() external returns (uint);

    function burnOptions(uint amount) external;

    function burnOptionsMaximum() external;
}