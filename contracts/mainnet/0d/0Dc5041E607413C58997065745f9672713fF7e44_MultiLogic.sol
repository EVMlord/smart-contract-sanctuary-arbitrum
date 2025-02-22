// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IStorage.sol";
import "./interfaces/ILogicContract.sol";
import "./interfaces/IStrategyContract.sol";
import "./utils/OwnableUpgradeableAdminable.sol";
import "./utils/UpgradeableBase.sol";

contract MultiLogic is UpgradeableBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct singleStrategy {
        address logicContract;
        address strategyContract;
    }

    address private storageContract;
    singleStrategy[] private multiStrategy;
    mapping(address => bool) private approvedTokens;
    mapping(address => bool) private approvedTokensLogic;
    mapping(address => mapping(address => uint256)) private dividePercentage;
    mapping(address => mapping(address => uint256)) private tokenAvailableLogic;
    mapping(address => mapping(address => uint256)) private tokenBalanceLogic;
    uint256 public multiStrategyLength;
    string[] public multiStrategyName;
    mapping(string => singleStrategy) private multiStrategyData;
    mapping(address => bool) public isExistLogic;
    address private constant ZERO_ADDRESS = address(0);

    event TakeToken(address token, address logic, uint256 amount);
    event ReturnToken(address token, uint256 amount);
    event ReleaseToken(address token, uint256 amount);
    event AddStrategy(string name, singleStrategy strategies);
    event InitStrategy(string[] strategiesName, singleStrategy[] strategies);
    event SetLogicTokenAvailable(
        uint256 amount,
        address token,
        uint256 deposit_flag
    );

    function __MultiLogicProxy_init() public initializer {
        UpgradeableBase.initialize();
        multiStrategyLength = 0;
    }

    receive() external payable {}

    modifier onlyStorage() {
        require(msg.sender == storageContract, "M1");
        _;
    }

    /**
     * @notice Check if the logic address exist
     */
    modifier onlyExistLogic() {
        require(isExistLogic[msg.sender] == true, "M4");
        _;
    }

    /*** User function ***/

    /**
     * @notice set Storage address
     * @param _storage storage address
     */
    function setStorage(address _storage) external onlyOwner {
        require(storageContract == ZERO_ADDRESS, "M5");
        storageContract = _storage;
    }

    /**
     * @notice Set the dividing percentage
     * @param _token token address
     * @param _percentages percentage array
     */
    function setPercentages(address _token, uint256[] memory _percentages)
        public
        onlyOwner
    {
        uint256 _count = multiStrategyLength;
        uint256 sumTotal = 0;
        uint256 index;
        uint256[] memory releaseAmounts = new uint256[](_count);
        uint256 sumReleaseAmount = 0;

        require(_percentages.length == _count, "M2");

        mapping(address => uint256)
            storage _tokenAvailable = tokenAvailableLogic[_token];
        mapping(address => uint256) storage _tokenBalance = tokenBalanceLogic[
            _token
        ];

        // Check sum of percentage
        {
            uint256 sumPercentage = 0;
            for (index = 0; index < _count; ) {
                sumPercentage += _percentages[index];
                unchecked {
                    ++index;
                }
            }
            require(sumPercentage == 10000, "M3");
        }

        // Get sum of total
        for (index = 0; index < _count; ) {
            singleStrategy memory sStrategy = multiStrategyData[
                multiStrategyName[index]
            ];

            // Calculate sum
            sumTotal +=
                _tokenAvailable[sStrategy.logicContract] +
                _tokenBalance[sStrategy.logicContract];

            // Set percentage
            dividePercentage[_token][sStrategy.logicContract] = _percentages[
                index
            ];

            unchecked {
                ++index;
            }
        }

        // Set avaliable, balance for each strategy
        if (sumTotal > 0) {
            uint256 sum = 0;
            for (index = 0; index < _count; ) {
                singleStrategy memory sStrategy = multiStrategyData[
                    multiStrategyName[index]
                ];

                // calculate total for each strategy
                uint256 newTotal;
                if (index == _count - 1) {
                    newTotal = sumTotal - sum;
                } else {
                    newTotal = (sumTotal * _percentages[index]) / 10000;
                    sum += newTotal;
                }

                if (newTotal < _tokenBalance[sStrategy.logicContract]) {
                    // If newTotal < balance, balance = newTotal, available = 0
                    releaseAmounts[index] =
                        _tokenBalance[sStrategy.logicContract] -
                        newTotal;
                    _tokenBalance[sStrategy.logicContract] = newTotal;
                    _tokenAvailable[sStrategy.logicContract] = 0;

                    sumReleaseAmount += releaseAmounts[index];
                } else {
                    // If newTotal > balance, available = newTotal - balance;
                    _tokenAvailable[sStrategy.logicContract] =
                        newTotal -
                        _tokenBalance[sStrategy.logicContract];
                }

                unchecked {
                    ++index;
                }
            }
        }

        // Release token for each strategy and send token to storage
        if (sumReleaseAmount > 0) {
            // ReleaseToken for each strategy and take token from Logic to MultiLogic
            for (index = 0; index < _count; ) {
                if (releaseAmounts[index] > 0) {
                    singleStrategy memory sStrategy = multiStrategyData[
                        multiStrategyName[index]
                    ];

                    IStrategy(sStrategy.strategyContract).releaseToken(
                        releaseAmounts[index],
                        _token
                    );

                    if (_token != ZERO_ADDRESS) {
                        IERC20Upgradeable(_token).safeTransferFrom(
                            sStrategy.logicContract,
                            address(this),
                            releaseAmounts[index]
                        );
                    }
                }

                unchecked {
                    ++index;
                }
            }

            // Send tokens to storage
            if (_token != ZERO_ADDRESS) {
                if (!approvedTokens[_token]) {
                    //if token not approved for storage
                    IERC20Upgradeable(_token).approve(
                        storageContract,
                        type(uint256).max
                    );
                    approvedTokens[_token] = true;
                }
            } else {
                _send(payable(storageContract), sumReleaseAmount);
            }

            IStorage(storageContract).returnToken(sumReleaseAmount, _token);
        }
    }

    /**
     * @notice Init the Logic address into MultiLogicProxy
     * @param _strategyName strategy name array
     * @param _multiStrategy strategy array
     */
    function initStrategies(
        string[] calldata _strategyName,
        singleStrategy[] calldata _multiStrategy
    ) external onlyOwner {
        uint256 count = _multiStrategy.length;
        uint256 nameCount = _strategyName.length;
        require(count == nameCount, "M2");
        require(count != 0, "M11");

        // Remove exist strategies
        for (uint256 i = 0; i < multiStrategyLength; ) {
            isExistLogic[
                multiStrategyData[multiStrategyName[i]].logicContract
            ] = false;

            unchecked {
                ++i;
            }
        }
        delete multiStrategyName;
        // Add new strategies

        for (uint256 i = 0; i < count; ) {
            require(_multiStrategy[i].logicContract != ZERO_ADDRESS, "M11");
            require(_multiStrategy[i].strategyContract != ZERO_ADDRESS, "M11");

            multiStrategyName.push(_strategyName[i]);
            multiStrategyData[_strategyName[i]] = _multiStrategy[i];
            isExistLogic[_multiStrategy[i].logicContract] = true;
            unchecked {
                ++i;
            }
        }
        multiStrategyLength = count;

        emit InitStrategy(_strategyName, _multiStrategy);
    }

    /**
     * @notice Set the Logic address into MultiLogicProxy
     * @param _strategyName strategy name
     * @param _multiStrategy strategy
     * @param _overwrite overwrite flag
     */
    function addStrategy(
        string memory _strategyName,
        singleStrategy memory _multiStrategy,
        bool _overwrite
    ) external onlyOwner {
        require(_multiStrategy.logicContract != ZERO_ADDRESS, "M11");
        require(_multiStrategy.strategyContract != ZERO_ADDRESS, "M11");

        bool exist = false;
        for (uint256 i = 0; i < multiStrategyLength; ) {
            if (
                keccak256(abi.encodePacked((multiStrategyName[i]))) ==
                keccak256(abi.encodePacked((_strategyName)))
            ) {
                require(_overwrite, "M9");
                exist = true;
                break;
            }
            unchecked {
                ++i;
            }
        }

        if (exist) {
            isExistLogic[
                multiStrategyData[_strategyName].logicContract
            ] = false;
        } else {
            multiStrategyName.push(_strategyName);
            multiStrategyLength++;
        }

        multiStrategyData[_strategyName] = _multiStrategy;
        isExistLogic[_multiStrategy.logicContract] = true;

        emit AddStrategy(_strategyName, _multiStrategy);
    }

    /**
     * @notice Set percentage of strategy to be 0
     * destroyAll for that strategy
     * rebalance existing strategies
     * @param _strategyName strategy name
     */
    function deactivateStrategy(string memory _strategyName)
        external
        onlyOwner
    {
        uint256 _multiStrategyLength = multiStrategyLength;

        // Check if exists and get index of strategy
        bool exist = false;
        uint256 indexOfStrategy = 0;
        for (uint256 i = 0; i < multiStrategyLength; ) {
            if (
                keccak256(abi.encodePacked((multiStrategyName[i]))) ==
                keccak256(abi.encodePacked((_strategyName)))
            ) {
                exist = true;
                indexOfStrategy = i;
                break;
            }
            unchecked {
                ++i;
            }
        }

        if (!exist) {
            return;
        }

        // Update Percentages of strategies
        address[] memory usedTokens = IStorage(storageContract).getUsedTokens();
        for (uint256 i = 0; i < usedTokens.length; ) {
            address _token = usedTokens[i];
            uint256[] memory newPercentages = new uint256[](
                _multiStrategyLength
            );

            singleStrategy memory sStrategy = multiStrategyData[
                multiStrategyName[indexOfStrategy]
            ];

            // Get percentage of strategy
            uint256 percentageOfStrategy = dividePercentage[_token][
                sStrategy.logicContract
            ];

            // if the percentage is 100%, destroyAll and update percentage, available, balance = 0
            if (percentageOfStrategy == 10000) {
                uint256 tokenBalance = tokenBalanceLogic[_token][
                    sStrategy.logicContract
                ];
                IStrategy(sStrategy.strategyContract).releaseToken(
                    tokenBalance,
                    _token
                );

                if (_token != ZERO_ADDRESS) {
                    IERC20Upgradeable(_token).safeTransferFrom(
                        sStrategy.logicContract,
                        address(this),
                        tokenBalance
                    );
                }

                IStorage(storageContract).returnToken(tokenBalance, _token);
                dividePercentage[_token][sStrategy.logicContract] = 0;
                tokenAvailableLogic[_token][sStrategy.logicContract] = 0;
                tokenBalanceLogic[_token][sStrategy.logicContract] = 0;
            } else {
                // If it is already deactivated, skip this token
                if (percentageOfStrategy > 0) {
                    // Calculate new percentages of strategy
                    uint256 sumPercentages = 0;
                    for (uint256 j = 0; j < _multiStrategyLength; ) {
                        if (j == indexOfStrategy) {
                            newPercentages[j] = 0;
                        } else {
                            newPercentages[j] =
                                (dividePercentage[_token][
                                    multiStrategyData[multiStrategyName[j]]
                                        .logicContract
                                ] * 10000) /
                                (10000 - percentageOfStrategy);

                            sumPercentages += newPercentages[j];
                        }
                        unchecked {
                            ++j;
                        }
                    }

                    // Fix odd
                    if (sumPercentages < 10000) {
                        if (indexOfStrategy == _multiStrategyLength - 1) {
                            newPercentages[_multiStrategyLength - 2] +=
                                10000 -
                                sumPercentages;
                        } else {
                            newPercentages[_multiStrategyLength - 1] +=
                                10000 -
                                sumPercentages;
                        }
                    }

                    // Update percentages
                    setPercentages(_token, newPercentages);
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    /*** Storage function ***/

    /**
     * @notice Set Token balance for each logic
     * @param _amount deposit amount
     * @param _token deposit token
     * @param _deposit_withdraw flag for deposit or withdraw 1 : increase, 0: decrease, 2: set
     */
    function setLogicTokenAvailable(
        uint256 _amount,
        address _token,
        uint256 _deposit_withdraw
    ) external {
        require(msg.sender == owner() || msg.sender == storageContract, "M1");

        uint256 _count = multiStrategyLength;
        uint256 _amountDelta = 0;
        uint256 sum = 0;

        for (uint256 i = 0; i < _count; i++) {
            address logicAddress = multiStrategyData[multiStrategyName[i]]
                .logicContract;

            uint256 newAvailableAmount = ((_amount *
                dividePercentage[_token][logicAddress]) / 10000);

            if (i == _count - 1) {
                // if the final strategy, newAvailableAmount = shifted delta from previous strategy
                newAvailableAmount = _amount - sum;
            } else {
                // newAvailableAmount += shifted delta from previous strategy
                newAvailableAmount += _amountDelta;
                sum += newAvailableAmount;
            }

            if (_deposit_withdraw == 1) {
                // increase
                tokenAvailableLogic[_token][logicAddress] += newAvailableAmount;
            } else if (_deposit_withdraw == 0) {
                // decrease
                if (
                    tokenAvailableLogic[_token][logicAddress] >=
                    newAvailableAmount
                ) {
                    tokenAvailableLogic[_token][
                        logicAddress
                    ] -= newAvailableAmount;
                    _amountDelta = 0;
                } else {
                    _amountDelta =
                        newAvailableAmount -
                        tokenAvailableLogic[_token][logicAddress];
                    tokenAvailableLogic[_token][logicAddress] = 0;
                    if (i < _count - 1) sum -= _amountDelta;
                }
            } else {
                // set
                tokenAvailableLogic[_token][logicAddress] = newAvailableAmount;
            }
        }

        // if we have delta, then decrease available for previous strategy
        if (_deposit_withdraw == 0 && _amountDelta > 0) {
            for (uint256 i = 0; i < _count; ) {
                singleStrategy memory sStrategy = multiStrategyData[
                    multiStrategyName[i]
                ];

                uint256 available = tokenAvailableLogic[_token][
                    sStrategy.logicContract
                ];
                if (available > 0) {
                    if (available >= _amountDelta) {
                        tokenAvailableLogic[_token][
                            sStrategy.logicContract
                        ] -= _amountDelta;
                        _amountDelta = 0;

                        break;
                    } else {
                        tokenAvailableLogic[_token][
                            sStrategy.logicContract
                        ] = 0;
                        _amountDelta -= available;
                    }
                }

                unchecked {
                    ++i;
                }
            }
        }

        emit SetLogicTokenAvailable(_amount, _token, _deposit_withdraw);
    }

    /**
     * @notice Transfer amount of token from Logic to Storage Contract.
     * @param _amount Amount of token
     * @param _token Address of token
     */
    function releaseToken(uint256 _amount, address _token)
        external
        onlyStorage
    {
        uint256 _count = multiStrategyLength;
        uint256 _amountDelta = 0;
        uint256[] memory releaseAmounts = new uint256[](_count);
        uint256 _amountReleaseSum = 0;

        for (uint256 i = 0; i < _count; ) {
            singleStrategy memory sStrategy = multiStrategyData[
                multiStrategyName[i]
            ];

            uint256 releaseAmount;
            if (i == _count - 1) {
                // For the final strategy, we calculate remains
                releaseAmount = _amount - _amountReleaseSum;
            } else {
                // releaseAmount = percentage + shifted delta from previous strategy
                releaseAmount =
                    (_amount *
                        dividePercentage[_token][sStrategy.logicContract]) /
                    10000 +
                    _amountDelta;
            }

            // If balance < releaseAmount, release balance and shift delta to next strategy
            uint256 balance = tokenBalanceLogic[_token][
                sStrategy.logicContract
            ];
            if (balance < releaseAmount) {
                _amountDelta = releaseAmount - balance;
                releaseAmount = balance;
            } else {
                _amountDelta = 0;
            }

            // Decrease balance
            if (releaseAmount > 0) {
                tokenBalanceLogic[_token][
                    sStrategy.logicContract
                ] -= releaseAmount;

                releaseAmounts[i] = releaseAmount;

                if (_amount == 0) {
                    break;
                }
            }

            _amountReleaseSum += releaseAmount;
            // We don't update tokenAvaliable, because it is updated in Storage

            unchecked {
                ++i;
            }
        }

        // if we have delta, then increase releaseAmount for available strategies
        if (_amountDelta > 0) {
            for (uint256 i = 0; i < _count; ) {
                singleStrategy memory sStrategy = multiStrategyData[
                    multiStrategyName[i]
                ];

                uint256 balance = tokenBalanceLogic[_token][
                    sStrategy.logicContract
                ];
                if (balance > 0) {
                    if (balance >= _amountDelta) {
                        releaseAmounts[i] += _amountDelta;
                        tokenBalanceLogic[_token][
                            sStrategy.logicContract
                        ] -= _amountDelta;
                        _amountDelta = 0;

                        break;
                    } else {
                        releaseAmounts[i] += balance;
                        tokenBalanceLogic[_token][sStrategy.logicContract] = 0;
                        _amountDelta -= balance;
                    }
                }

                unchecked {
                    ++i;
                }
            }
        }

        require(_amountDelta == 0, "M7");

        // Interaction
        for (uint256 i = 0; i < _count; ) {
            if (releaseAmounts[i] > 0) {
                singleStrategy memory sStrategy = multiStrategyData[
                    multiStrategyName[i]
                ];

                IStrategy(sStrategy.strategyContract).releaseToken(
                    releaseAmounts[i],
                    _token
                );

                if (_token != ZERO_ADDRESS) {
                    IERC20Upgradeable(_token).safeTransferFrom(
                        sStrategy.logicContract,
                        address(this),
                        releaseAmounts[i]
                    );
                }
            }

            unchecked {
                ++i;
            }
        }

        if (_token == ZERO_ADDRESS) {
            require(address(this).balance >= _amount, "M7");
            _send(payable(storageContract), _amount);
        } else {
            if (!approvedTokens[_token]) {
                //if token not approved for storage
                IERC20Upgradeable(_token).approve(
                    storageContract,
                    type(uint256).max
                );
                approvedTokens[_token] = true;
            }
        }

        emit ReleaseToken(_token, _amount);
    }

    /*** Logic function ***/

    /**
     * @notice Transfer amount of token from Storage to Logic Contract.
     * @param _amount Amount of token
     * @param _token Address of token
     */
    function takeToken(uint256 _amount, address _token)
        external
        onlyExistLogic
    {
        uint256 tokenAvailable = getTokenAvailable(_token, msg.sender);
        require(_amount <= tokenAvailable, "M6");

        tokenAvailableLogic[_token][msg.sender] -= _amount;
        tokenBalanceLogic[_token][msg.sender] += _amount;

        // Interaction
        IStorage(storageContract).takeToken(_amount, _token);

        if (_token == ZERO_ADDRESS) {
            require(address(this).balance >= _amount, "M7");
            _send(payable(msg.sender), _amount);
        } else {
            IERC20Upgradeable(_token).safeTransfer(msg.sender, _amount);
        }

        emit TakeToken(_token, msg.sender, _amount);
    }

    /**
     * @notice Transfer amount of token from Logic to Storage Contract.
     * @param _amount Amount of token
     * @param _token Address of token
     */
    function returnToken(uint256 _amount, address _token)
        external
        onlyExistLogic
    {
        require(_amount <= tokenBalanceLogic[_token][msg.sender], "M6");

        tokenAvailableLogic[_token][msg.sender] += _amount;
        tokenBalanceLogic[_token][msg.sender] -= _amount;

        // Interaction
        if (_token == ZERO_ADDRESS) {
            require(address(this).balance >= _amount, "M7");
            _send(payable(storageContract), _amount);
        } else {
            if (!approvedTokens[_token]) {
                //if token not approved for storage
                IERC20Upgradeable(_token).approve(
                    storageContract,
                    type(uint256).max
                );
                approvedTokens[_token] = true;
            }

            IERC20Upgradeable(_token).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );
        }

        IStorage(storageContract).returnToken(_amount, _token);

        emit ReturnToken(_token, _amount);
    }

    /**
     * @notice Take amount BLID from Logic contract  and distributes earned BLID
     * @param _amount Amount of distributes earned BLID
     * @param _blidToken blidToken address
     */
    function addEarn(uint256 _amount, address _blidToken)
        external
        onlyExistLogic
    {
        if (!approvedTokens[_blidToken]) {
            //if token not approved for storage
            IERC20Upgradeable(_blidToken).approve(
                storageContract,
                type(uint256).max
            );
            approvedTokens[_blidToken] = true;
        }

        IERC20Upgradeable(_blidToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        IStorage(storageContract).addEarn(_amount);
    }

    /*** Public view function ***/

    /**
     * @notice Return deposited usd
     */
    function getTotalDeposit() external view returns (uint256) {
        return IStorage(storageContract).getTotalDeposit();
    }

    /**
     * @notice Returns the available amount of token for the logic
     * @param _token deposit token
     * @param _logicAddress logic Address
     */
    function getTokenAvailable(address _token, address _logicAddress)
        public
        view
        returns (uint256)
    {
        return tokenAvailableLogic[_token][_logicAddress];
    }

    /**
     * @notice Returns the taken amount of token for the logic
     * @param _token deposit token
     * @param _logicAddress logic Address
     */
    function getTokenTaken(address _token, address _logicAddress)
        public
        view
        returns (uint256)
    {
        return tokenBalanceLogic[_token][_logicAddress];
    }

    /**
     * @notice Return percentage value
     * @param _token deposit token
     */
    function getPercentage(address _token)
        external
        view
        returns (uint256[] memory)
    {
        uint256 _count = multiStrategyLength;
        uint256[] memory ret = new uint256[](_count);
        for (uint256 i = 0; i < _count; i++) {
            ret[i] = dividePercentage[_token][
                multiStrategyData[multiStrategyName[i]].logicContract
            ];
        }
        return ret;
    }

    /**
     * @notice Set the Logic address into MultiLogicProxy
     * @param _name strategy name
     */
    function strategyInfo(string memory _name)
        external
        view
        returns (address, address)
    {
        bool exist = false;
        for (uint256 i = 0; i < multiStrategyLength; ) {
            if (
                keccak256(abi.encodePacked((multiStrategyName[i]))) ==
                keccak256(abi.encodePacked((_name)))
            ) {
                exist = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
        require(exist == true, "M10");
        return (
            multiStrategyData[_name].logicContract,
            multiStrategyData[_name].strategyContract
        );
    }

    /**
     * @notice Get used tokens in storage
     */
    function getUsedTokensStorage() external view returns (address[] memory) {
        return IStorage(storageContract).getUsedTokens();
    }

    /*** Private function ***/

    /**
     * @notice Send ETH to address
     * @param _to target address to receive ETH
     * @param amount ETH amount (wei) to be sent
     */
    function _send(address payable _to, uint256 amount) private {
        (bool sent, ) = _to.call{value: amount}("");
        require(sent, "M8");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IStorage {
    function takeToken(uint256 amount, address token) external;

    function returnToken(uint256 amount, address token) external;

    function addEarn(uint256 amount) external;

    function _isUsedToken(address _token) external returns (bool);

    function getTokenDeposit(address account, address token)
        external
        view
        returns (uint256);

    function getTotalDeposit() external view returns (uint256);

    function getTokenBalance(address token) external view returns (uint256);

    function getTokenDeposited(address token) external view returns (uint256);

    function depositOnBehalf(
        uint256 amount,
        address token,
        address accountAddress
    ) external;

    function getUsedTokens() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IWETH.sol";
import "./IPancakeV3.sol";

interface ILogicContract {
    function addXTokens(
        address token,
        address xToken,
        uint8 leadingTokenType
    ) external;

    function approveTokenForSwap(address token) external;

    function claim(address[] calldata xTokens, uint8 leadingTokenType) external;

    function mint(address xToken, uint256 mintAmount)
        external
        returns (uint256);

    function borrow(
        address xToken,
        uint256 borrowAmount,
        uint8 leadingTokenType
    ) external returns (uint256);

    function repayBorrow(address xToken, uint256 repayAmount) external;

    function redeemUnderlying(address xToken, uint256 redeemAmount)
        external
        returns (uint256);

    function swapExactTokensForTokens(
        address swap,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        address swap,
        uint256 amountETH,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        address swap,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        address swap,
        uint256 amountETH,
        uint256 amountOut,
        address[] calldata path,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address swap,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address swap,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function addLiquidityETH(
        address swap,
        address token,
        uint256 amountTokenDesired,
        uint256 amountETHDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
    )
        external
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidityETH(
        address swap,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH);

    function addEarnToStorage(uint256 amount) external;

    function enterMarkets(address[] calldata xTokens, uint8 leadingTokenType)
        external
        returns (uint256[] memory);

    function returnTokenToStorage(uint256 amount, address token) external;

    function takeTokenFromStorage(uint256 amount, address token) external;

    function returnETHToMultiLogicProxy(uint256 amount) external;

    function deposit(
        address swapMaster,
        uint256 _pid,
        uint256 _amount
    ) external;

    function withdraw(
        address swapMaster,
        uint256 _pid,
        uint256 _amount
    ) external;

    function returnToken(uint256 amount, address token) external; // for StorageV2 only
}

/************* New Architecture *************/
interface ISwapLogic {
    function swap(
        address swapRouter,
        uint256 amountIn,
        uint256 amountOut,
        address[] memory path,
        bool isExactInput,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swap(
        address swapRouter,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOut,
        address[] memory path,
        bool isExactInput,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

interface ILogic is ISwapLogic {
    function addEarnToStorage(uint256 amount) external;

    function returnTokenToStorage(uint256 amount, address token) external;

    function takeTokenFromStorage(uint256 amount, address token) external;

    function returnETHToMultiLogicProxy(uint256 amount) external;

    function multiLogicProxy() external view returns (address);

    function approveTokenForSwap(address _swap, address token) external;
}

interface ILendingLogic is ILogic {
    function isXTokenUsed(address xToken) external view returns (bool);

    function addXTokens(address token, address xToken) external;

    function comptroller() external view returns (address);

    function getAllMarkets() external view returns (address[] memory);

    function checkEnteredMarket(address xToken) external view returns (bool);

    function getUnderlyingPrice(address xToken) external view returns (uint256);

    function getUnderlying(address xToken) external view returns (address);

    function getXToken(address token) external view returns (address);

    function getCollateralFactor(address xToken)
        external
        view
        returns (uint256);

    function rewardToken() external view returns (address);

    function enterMarkets(address[] calldata xTokens)
        external
        returns (uint256[] memory);

    function claim() external;

    function mint(address xToken, uint256 mintAmount)
        external
        returns (uint256);

    function borrow(address xToken, uint256 borrowAmount)
        external
        returns (uint256);

    function repayBorrow(address xToken, uint256 repayAmount)
        external
        returns (uint256);

    function redeemUnderlying(address xToken, uint256 redeemAmount)
        external
        returns (uint256);

    function redeem(address xToken, uint256 redeemTokenAmount)
        external
        returns (uint256);

    function accrueInterest(address xToken) external;
}

interface IFarmingLogic is ILogic {
    function addLiquidity(
        address swap,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address swap,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function farmingDeposit(
        address swapMaster,
        uint256 _pid,
        uint256 _amount
    ) external;

    function farmingWithdraw(
        address swapMaster,
        uint256 _pid,
        uint256 _amount
    ) external;
}

struct BuildPairParams {
    address logic;
    address pool;
    uint256 token0Price;
    uint256 token1Price;
    uint24 minPricePercentage;
    uint24 maxPricePercentage;
    uint256 amountUsd;
}

struct ChangeLiquidityParams {
    address logic;
    address pool;
    uint256 token0Price;
    uint256 token1Price;
    int24 tickLower;
    int24 tickUpper;
    uint256 amountUsd;
}

struct AddLiquidityParams {
    address token0;
    address token1;
    uint256 amount0;
    uint256 amount1;
    int24 tickLower;
    int24 tickUpper;
    uint24 fee;
    uint256 tokenId;
}

struct RemoveLiquidityParams {
    uint256 tokenId;
    address pool;
    uint128 liquidity;
    uint256 amount0;
    uint256 amount1;
}

interface IFarmingV3Logic {
    function getAmountsByPosition(uint256 _tokenId, address _pool)
        external
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidity
        );

    function calcFeeAmountsByPosition(uint256 _tokenId, address pool)
        external
        view
        returns (uint256 fee0, uint256 fee1);

    function getPositionInfo(uint256 _tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    function addLiquidity(AddLiquidityParams memory params)
        external
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function removeLiquidity(RemoveLiquidityParams memory params)
        external
        returns (uint256 amount0, uint256 amount1);

    function addToFarming(uint256 _tokenId) external;

    function removeFromFarming(uint256 _tokenId) external;

    function claimRewards(uint256 _tokenId) external returns (uint256);

    function rewardsToken() external view returns (address);

    function getRewardsAmount(uint256 _tokenId) external view returns (uint256);

    function burnPosition(uint256 _tokenId) external;

    function collectFees(uint256 _tokenId, address _pool)
        external
        returns (uint256 amount0, uint256 amount1);

    function WETH() external view returns (IWETH);

    function nftPositionManager()
        external
        view
        returns (INonfungiblePositionManager);

    function swapRouter() external view returns (IPancakeV3Router);

    function percentToTickDiff(uint24 percentDiff)
        external
        view
        returns (int24 tickDiff);

    function swapHelper(
        address swapRouter,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOut,
        address[] memory path,
        bool isExactInput,
        uint256 deadline
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IStrategyStatistics.sol";

interface IStrategyVenus {
    function farmingPair() external view returns (address);

    function lendToken() external;

    function build(uint256 usdAmount) external;

    function destroy(uint256 percentage) external;

    function claimRewards(uint8 mode) external;
}

interface IStrategy {
    function releaseToken(uint256 amount, address token) external; // onlyMultiLogicProxy

    function logic() external view returns (address);

    function useToken() external; // Automation

    function rebalance() external; // Automation

    function checkUseToken() external view returns (bool); // Automation

    function checkRebalance() external view returns (bool); // Automation

    function destroyAll() external; // onlyOwnerAdmin

    function claimRewards() external; // onlyOwnerAdmin
}

interface IStrategyFarmingV3 {
    function checkRebalancePriceRange() external view returns (bool); // Automation

    function rebalancePriceRange() external; // Automation

    function collectFees() external; // Automation

    function getPairs() external view returns (Pair[] memory);
}

interface ILbfPairManager {
    function build(uint256 _usdAmount) external;

    function destroy(uint256 _usdAmount, DestroyMode _mode) external;

    function getPairs() external view returns (Pair[] memory);

    function getTokens()
        external
        view
        returns (address[] memory arrTokens, uint256 len);

    function buildPair(uint256 index) external;

    function buildPair(
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) external;

    function destroyPair(uint256 index)
        external
        returns (uint256 amount0Out, uint256 amount1Out);

    function destroyPair(
        uint256 index,
        uint256 amount0,
        uint256 amount1,
        uint128 liquidity,
        bool shoudBurn
    ) external returns (uint256 amount0Out, uint256 amount1Out);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract OwnableUpgradeableAdminable is OwnableUpgradeable {
    address private _admin;

    event SetAdmin(address admin);

    modifier onlyAdmin() virtual {
        require(msg.sender == _admin, "OA1");
        _;
    }

    modifier onlyOwnerAndAdmin() virtual {
        require(msg.sender == owner() || msg.sender == _admin, "OA2");
        _;
    }

    /**
     * @notice Set admin
     * @param newAdmin Addres of new admin
     */
    function setAdmin(address newAdmin) external onlyOwner {
        _admin = newAdmin;
        emit SetAdmin(newAdmin);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./OwnableUpgradeableVersionable.sol";
import "./OwnableUpgradeableAdminable.sol";

abstract contract UpgradeableBase is
    Initializable,
    OwnableUpgradeableVersionable,
    OwnableUpgradeableAdminable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    function initialize() public virtual onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
        onlyOwner
    {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IPancakeV3Factory {
    function getPool(
        address _fromAsset,
        address _toAsset,
        uint24 fee
    ) external view returns (address);
}

interface IPancakeV3Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountOut);

    function factory() external view returns (address);

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams memory params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams memory params)
        external
        payable
        returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    function refundETH() external payable;
}

interface IPancakeV3MasterChef {
    function CAKE() external view returns (address);

    function pendingCake(uint256 _tokenId)
        external
        view
        returns (uint256 reward);

    function harvest(uint256 _tokenId, address _to)
        external
        returns (uint256 reward);

    function withdraw(uint256 _tokenId, address _to)
        external
        returns (uint256 reward);

    function increaseLiquidity(
        INonfungiblePositionManager.IncreaseLiquidityParams memory params
    )
        external
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function decreaseLiquidity(
        INonfungiblePositionManager.DecreaseLiquidityParams memory params
    ) external returns (uint256 amount0, uint256 amount1);

    function collect(INonfungiblePositionManager.CollectParams memory params)
        external
        returns (uint256 amount0, uint256 amount1);
}

interface IPancakeV3Pool {
    // Has a bit different signature than the original IUniswapV3Pool
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint32 feeProtocol,
            bool unlocked
        );

    function token0() external view returns (address);

    function token1() external view returns (address);

    function feeGrowthGlobal0X128() external view returns (uint256);

    function feeGrowthGlobal1X128() external view returns (uint256);

    function fee() external view returns (uint24);

    function ticks(int24 tokenId)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    function tickSpacing() external view returns (int24);
}

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    function mint(INonfungiblePositionManager.MintParams memory params)
        external
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function increaseLiquidity(
        INonfungiblePositionManager.IncreaseLiquidityParams memory params
    )
        external
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function decreaseLiquidity(
        INonfungiblePositionManager.DecreaseLiquidityParams memory params
    ) external returns (uint256 amount0, uint256 amount1);

    function collect(INonfungiblePositionManager.CollectParams memory params)
        external
        returns (uint256 amount0, uint256 amount1);

    function burn(uint256 _tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address spender, uint256 amount) external returns (bool);

    function ownerOf(uint256 tokenId) external returns (address);

    function refundETH() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

struct XTokenInfo {
    string symbol;
    address xToken;
    uint256 totalSupply;
    uint256 totalSupplyUSD;
    uint256 lendingAmount;
    uint256 lendingAmountUSD;
    uint256 borrowAmount;
    uint256 borrowAmountUSD;
    uint256 borrowLimit;
    uint256 borrowLimitUSD;
    uint256 underlyingBalance;
    uint256 priceUSD;
}

struct XTokenAnalytics {
    string symbol;
    address platformAddress;
    string underlyingSymbol;
    address underlyingAddress;
    uint256 underlyingDecimals;
    uint256 underlyingPrice;
    uint256 totalSupply;
    uint256 totalSupplyUSD;
    uint256 totalBorrows;
    uint256 totalBorrowsUSD;
    uint256 liquidity;
    uint256 collateralFactor;
    uint256 borrowApy;
    uint256 borrowRewardsApy;
    uint256 supplyApy;
    uint256 supplyRewardsApy;
}

struct StrategyStatistics {
    XTokenInfo[] xTokensStatistics;
    WalletInfo[] walletStatistics;
    uint256 lendingEarnedUSD;
    uint256 totalSupplyUSD;
    uint256 totalBorrowUSD;
    uint256 totalBorrowLimitUSD;
    uint256 borrowRate;
    uint256 storageAvailableUSD;
    int256 totalAmountUSD;
}

struct LbfStrategyStatistics {
    XTokenInfo[] xTokensStatistics;
    WalletInfo[] walletStatistics;
    uint256 lendingEarnedUSD;
    uint256 totalSupplyUSD;
    uint256 totalBorrowUSD;
    uint256 totalBorrowLimitUSD;
    uint256 borrowRate;
    uint256 storageAvailableUSD;
    StakedInfo[] stakedStatistics;
    uint256 stakedAmountUSD;
    uint256 farmingRewardsAmountUSD;
    int256 totalAmountUSD;
}

struct FarmingPairInfo {
    uint256 index;
    address lpToken;
    uint256 farmingAmount;
    uint256 rewardsAmount;
    uint256 rewardsAmountUSD;
}

struct WalletInfo {
    string symbol;
    address token;
    uint256 balance;
    uint256 balanceUSD;
}

struct PriceInfo {
    address token;
    uint256 priceUSD;
}

struct StakedTokenAmountUSD {
    address token;
    uint256 amount;
    uint256 amountUSD;
    uint256 fee;
    uint256 feeUSD;
}

struct StakedInfo {
    uint256 tokenId;
    StakedTokenAmountUSD token0Info;
    StakedTokenAmountUSD token1Info;
}

struct Pair {
    address pool;
    uint24 percentage;
    uint24 minPricePercentage;
    uint24 maxPricePercentage;
    uint160 sqrtPriceThreshold; // 2**96 * sqrt(percentage)
    uint256 tokenId;
}

enum DestroyMode {
    // Remove liquidity from all pairs based on percentages
    Proportional,
    // Remove maximum liquidity from pair by pair
    Greedy,
    // Remove all liquidity
    Full
}

interface IStrategyStatistics {
    function getXTokenInfo(address _asset, address comptroller)
        external
        view
        returns (XTokenAnalytics memory);

    function getXTokensInfo(address comptroller)
        external
        view
        returns (XTokenAnalytics[] memory);

    function getStrategyStatistics(address logic)
        external
        view
        returns (StrategyStatistics memory statistics);

    function getStrategyXTokenInfo(address xToken, address logic)
        external
        view
        returns (XTokenInfo memory tokenInfo);

    function getStrategyXTokenInfoCompact(address xToken, address logic)
        external
        view
        returns (
            uint256 totalSupply,
            uint256 borrowLimit,
            uint256 borrowAmount
        );

    function getRewardsTokenPrice(address comptroller, address rewardsToken)
        external
        view
        returns (uint256 priceUSD);

    function getEnteredMarkets(address comptroller, address logic)
        external
        view
        returns (address[] memory markets);
}

interface IFarmingStatistics {
    function getStakedPortfolio(address logic, address strategy)
        external
        view
        returns (StakedInfo[] memory);

    function getFarmingRewardsAmount(address logic, address strategy)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract OwnableUpgradeableVersionable is OwnableUpgradeable {
    string private _version;
    string private _purpose;

    event UpgradeVersion(string version, string purpose);

    function getVersion() external view returns (string memory) {
        return _version;
    }

    function getPurpose() external view returns (string memory) {
        return _purpose;
    }

    /**
     * @notice Set version and purpose
     * @param version Version string, ex : 1.2.0
     * @param purpose Purpose string
     */
    function upgradeVersion(string memory version, string memory purpose)
        external
        onlyOwner
    {
        require(bytes(version).length != 0, "OV1");

        _version = version;
        _purpose = purpose;

        emit UpgradeVersion(version, purpose);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/IERC1967Upgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.9._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}