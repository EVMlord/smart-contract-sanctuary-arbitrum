// SPDX-License-Identifier: MIT

import "./Idea.sol";

pragma solidity ^0.8.11;

/**
 * A wrapper for the Idea contract used for centralizing events emitted by the
 * child contract.
 */
contract Factory {
	Idea[] public registry;

	/* A user created an instance of the factory */
	event FactoryCreated();

	/* A user created an instance of the Idea contract. */
	event IdeaCreated(address idea);

	constructor() {
		emit FactoryCreated();
	}

	/**
	 * Calls the constructor on the Idea contract with the specified arguments
	 * and registers it in the registry.
	 */
	function createIdea(string memory ideaName, string memory ideaTicker, uint256 ideaShares, string memory datumIpfsHash) external returns (address) {
		Idea created = new Idea(ideaName, ideaTicker, ideaShares, datumIpfsHash);
		registry.push(created);

		// Notify listeners, and transfer to msg.sender, because the registry is msg.sender
		emit IdeaCreated(address(created));
		require(created.transfer(msg.sender, ideaShares), "Failed to allocate supply.");

		return address(created);
	}
}

// SPDX-License-Identifier: MIT

import "../Idea.sol";
import "./Funding.sol";

pragma solidity ^0.8.11;

enum VoteKind {
	For,
	Against
}

/**
 * Details of individual votes must be stored to allow "undo" functionality.
 */
struct Vote {
	uint256 votes;
	VoteKind kind;
}

/**
 * Represents an ongoing vote to implement a new funding rate for an idea.
 * Votes are weighted based on balances held.
 */
contract Prop {
	/* The idea constituting the voting body */
	Idea public governed;

	/* The idea being funded by the prop */
	address public toFund;

	/* The funding rate being voted on */
	FundingRate internal rate;

	/* Users that voted on the proposal - should receive a refund after */
	mapping (address => Vote) public refunds;

	/* Where metadata about the proposal is stored */
	string public ipfsAddr;
	uint256 public nVoters;

	uint256 public votesFor;
	uint256 public votesAgainst;

	/* The title of the proposal */
	string public title;

	address[] public voters;

	/* The number of seconds that the vote lasts */
	uint256 public expiresAt;

	/* A new proposal was created, the details of which are on IPFS */
	event NewProposal(Prop prop, Idea governed, address toFund, string propIpfsHash, uint256 expiresAt);

	/* A user voted on a new rate for the proposal */
	event VoteCast(address voter, uint256 votes, VoteKind kind);

	modifier isActive {
		require(block.timestamp < expiresAt, "Voting on proposal has closed.");
		_;
	}

	/**
	 * Creates a new proposal, whose details should be on IPFS already, and that
	 * expires at the indicated time.
	 *
	 * @param _propName - The title of the proposal
	 * @param _jurisdiction - The token measuring votes
	 * @param _toFund - The idea whose funding is being voted on
	 * @param _token - The token being used to fund the idea
	 * @param _fundingType - How the reward should be fundraised (i.e., minting or from the treasury)
	 * @param _proposalIpfsHash - The details of the proposal, in any form, available
	 * on IPFS
	 * @param _voteExpiry - The number of seconds that the vote can last for
	 */
	constructor(string memory _propName, Idea _jurisdiction, address _toFund, address _token, FundingType _fundingType, uint256 _fundingAmount, string memory _proposalIpfsHash, uint256 _voteExpiry) {
		title = _propName;
		governed = _jurisdiction;
		toFund = _toFund;
		rate = FundingRate(_token, _fundingAmount, false, _fundingType);
		expiresAt = _voteExpiry;
		ipfsAddr = _proposalIpfsHash;

		emit NewProposal(this, _jurisdiction, _toFund, _proposalIpfsHash, expiresAt);
	}

	/**
	 * Delegates the specified number of votes (tokens) to this proposal with
	 * the given vote details.
	 */
	function vote(uint256 _votes, VoteKind _kind) external isActive {
		require(refunds[msg.sender].votes >= _votes || governed.transferFrom(msg.sender, address(this), _votes - refunds[msg.sender].votes), "Failed to delegate votes");

		// De-register old votes, and add the user as a voter
		if (refunds[msg.sender].votes > 0) {
			if (refunds[msg.sender].votes > _votes) {
				// Replace the user's old vote by returning their tokens
				uint256 diffRefund = refunds[msg.sender].votes - _votes;

				require(governed.transfer(msg.sender, diffRefund), "Failed to refund freed votes");
			}

			if (refunds[msg.sender].kind == VoteKind.For) {
				votesFor -= refunds[msg.sender].votes;
			} else {
				votesAgainst -= refunds[msg.sender].votes;
			}
		} else if (_votes > 0) {
			voters.push(msg.sender);
			nVoters++;
		}

		// Votes have to be weighted by their balance of the governing token
		if (_kind == VoteKind.For) {
			votesFor += _votes;
		} else {
			votesAgainst += _votes;
		}

		refunds[msg.sender] = Vote(_votes, _kind);
		emit VoteCast(msg.sender, _votes, _kind);
	}

	/**
	 * Deallocates all votes from the user.
	 */
	function refundVotes() external isActive {
		require(refunds[msg.sender].votes > 0, "No votes left to refund.");

		uint256 w = refunds[msg.sender].votes;

		// Refund the user
		require(governed.transfer(msg.sender, w), "Failed to refund votes");

		// Subtract their weighted votes from the total
		if (refunds[msg.sender].kind == VoteKind.For) {
			votesFor -= w;
		} else {
			votesAgainst -= w;
		}

		// Remove the user's refund entry
		delete refunds[msg.sender];

		for (uint256 i = 0; i < nVoters; i++) {
			if (voters[i] == msg.sender) {
				voters[i] = voters[nVoters - 1];
				voters.pop();

				break;
			}
		}

		nVoters--;
	}

	/**
	 * Refunds token votes to all voters, if the msg.sender is the governing
	 * contract.
	 */
	function refundAll() external returns (bool) {
		// Not any user can call refund
		require(msg.sender == address(governed), "Refunder is not the governor");

		// Refund all voters
		for (uint i = 0; i < nVoters; i++) {
			address voter = address(voters[i]);

			require(governed.transfer(voter, refunds[voter].votes), "Failed to refund all voters");
		}

		// All voters were successfully refunded
		return true;
	}

	/**
	 * Gets the current funding rate used by the proposal.
	 */
	function finalFundsRate() external view returns (FundingRate memory) {
		return rate;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/* Funds can be designed to be spent from a treasury of saved funds in a
 * governance contract, or be designated to be minted. */
enum FundingType {
	TREASURY,
	MINT
}

struct FundingRate {
	/* The token used for funding. Null for ETH */
	address token;

	/* The number of tokens to be allocated in total */
	uint256 value;

	/* Whether the funds have been spent or not */
	bool spent;

	/* The manner by which the funding is executed */
	FundingType kind;
}

// SPDX-License-Identifier: MIT

import "./governance/Funding.sol";
import "./governance/Prop.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity ^0.8.11;

/* Represents the governance contract / semi-fungible NFT of an idea in the
 * value tree. */
contract Idea is ERC20 {
	/* Funding rates for derivative ideas */
	mapping (address => FundingRate) public fundedIdeas;

	/* Ideas connected to the current idea */
	address[] public children;

	/* Proposals submitted to the DAO */
	mapping (address => bool) public propSubmitted;
	address[] public proposals;

	/* The location of the idea on IPFS */
	string public ipfsAddr;

	/* The idea, and its datum have been committed to the blockchain. */
	event IdeaRecorded(string ipfsAddr);

	/* A child idea has had a new funds rate finalized. */
	event IdeaFunded(Prop prop, address to, FundingRate rate);

	/* A proposal was submitted by a user */
	event ProposalSubmitted(Prop prop);

	/* A proposal failed to meet a 51% majority */
	event ProposalRejected(Prop prop);

	/* An instance of a child's funding has been released. */
	event FundingDispersed(address to, FundingRate rate);

	// Ensures that the given address is a funded child idea
	modifier isChild(address child) {
		FundingRate memory rate = fundedIdeas[child];

		// The specified contract must be a child that is funded by this governing contract
		require(rate.value > 0, "Proposal doesn't allocate any funds");

		_;
	}

	/**
	 * Creates a new idea from the given datum stored on IPFS, and idea token attributes.
	 */
	constructor(string memory ideaName, string memory ideaTicker, uint256 ideaShares, string memory datumIpfsHash) ERC20(ideaName, ideaTicker) {
		_mint(msg.sender, ideaShares);
		ipfsAddr = datumIpfsHash;

		emit IdeaRecorded(datumIpfsHash);
	}

	/**
	 * Register a proposal in the registry of current proposals for the DAO.
	 */
	function submitProp(string memory _propName, Idea _jurisdiction, address _toFund, address _token, FundingType _fundingType, uint256 _fundingAmount, string memory _proposalIpfsHash, uint256 _voteExpiry) external {
		require(address(_jurisdiction) == address(this), "Governor of proposal must be this idea");

		Prop proposal = new Prop(_propName, _jurisdiction, _toFund, _token, _fundingType, _fundingAmount, _proposalIpfsHash, _voteExpiry);

		proposals.push(address(proposal));
		propSubmitted[address(proposal)] = true;
		emit ProposalSubmitted(proposal);
	}

	/**
	 * Finalizes the given proposition if it has past its expiry date.
	 */
	function finalizeProp(Prop proposal) external {
		require(block.timestamp >= proposal.expiresAt(), "Vote has not yet terminated.");

		// Refund all voters - this must be completed before the vote can be terminated
		require(proposal.refundAll(), "Failed to refund all voters");

		// The new funds rate must not be recorded unless the proposal passed
		if (proposal.votesFor() <= totalSupply() / 2) {
			emit ProposalRejected(proposal);

			return;
		}

		// Record the new funds rate
		address toFund = proposal.toFund();
		FundingRate memory rate = proposal.finalFundsRate();

		for (uint256 i = 0; i < children.length; i++) {
			if (children[i] == toFund) {
				children[i] = children[children.length - 1];
				children.pop();

				break;
			}
		}

		fundedIdeas[toFund].value = 0;
		children.push(toFund);

		fundedIdeas[toFund] = rate;
		emit IdeaFunded(proposal, toFund, rate);
	}

	/**
	 * Disperses funding to the calling Idea, if it is a child in the
	 * jurisdiction of the current token, and has funds to be allocated.
	 */
	function disperseFunding(address idea) external isChild(idea) {
		FundingRate storage rate = fundedIdeas[idea];

		require(!rate.spent, "Funding already spent");

		// The number of tokens to disperse
		uint256 tokens = rate.value;

		// The governing contract has to have funds left in the designated token to transfer to the child
		// The idea can be rewarded in ETH or an ERC-20
		address thisAddr = address(this);

		if (fundedIdeas[idea].token == address(0x00)) {
			require(thisAddr.balance >= rate.value, "Not enough ETH for designated funds");

			(bool sent, ) = payable(idea).call{value: tokens}("");

			require(sent, "Failed to disperse ETH rewards");
		} else {
			// If the reward is in our own token, mint it
			if (rate.kind == FundingType.MINT) {
				require(rate.token == thisAddr, "Cannot mint funds for a foreign token");

				_mint(idea, tokens);
			} else {
				require(IERC20 (rate.token).transfer(idea, tokens), "Failed to disperse ERC rewards");
			}
		}

		rate.spent = true;

		emit FundingDispersed(idea, rate);
	}

	/**
	 * Gets the number of children funded by the idea.
	 */
	function numChildren() external view returns (uint256) {
		return children.length;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}