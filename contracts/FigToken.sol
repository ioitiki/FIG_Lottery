pragma solidity ^0.4.18;
pragma experimental ABIEncoderV2;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
          allowed[msg.sender][_spender] = 0;
        } else {
          allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract FigToken is StandardToken {

    string public constant name = "FigToken";
    string public constant symbol = "FIG";
    uint8 public constant decimals = 2;

    uint public constant INITIAL_SUPPLY = 2000000;

    function FigToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        Transfer(0x0, msg.sender, INITIAL_SUPPLY);
        wallets[msg.sender] = Wallet(INITIAL_SUPPLY, "admin");
    }

    struct Wallet {
        uint balance;
        string name;
    }
    mapping(address => Wallet) public wallets;

    struct Bet {
        uint value;
        uint24 numbers;
        uint24 drawingHash;
        uint blockNum;
        uint score;
        uint winnings;

    }

    mapping(address => Bet) public bets;

    function bet(uint _value, uint _numbers) public {
        uint256 _blockHash = uint256(block.blockhash(block.number - 1));

        if(((_blockHash % 100000000) / 1000000) % 10 == 0) {
            uint24 _drawingHash = uint24(_blockHash % 10000000) + 5000000;
            bets[msg.sender] = Bet({
              value: _value,
              numbers: uint24(_numbers),
              drawingHash: _drawingHash,
              blockNum: uint(block.number),
              score: 0,
              winnings: 0
            });
        } else {
            bets[msg.sender] = Bet({
              value: _value,
              numbers: uint24(_numbers),
              drawingHash: uint24(_blockHash % 10000000),
              blockNum: uint(block.number),
              score: 0,
              winnings: 0
            });
        };
        wallets[msg.sender].balance -= _value;
    }

    function payout(uint24 _numbers, uint24 _drawingHash) public {
        uint24 matches =
            (((_numbers % 10) % 5) - ((_drawingHash % 10) % 5) == 0 ? 1 : 0 ) +
            ((((_numbers / 10) % 10) % 5) - (((_drawingHash / 10) % 10) % 5) == 0 ? 1 : 0 ) +
            ((((_numbers / 100) % 10) % 5) - (((_drawingHash / 100) % 10) % 5) == 0 ? 1 : 0 ) +
            ((((_numbers / 1000) % 10) % 5) - (((_drawingHash / 1000) % 10) % 5) == 0 ? 1 : 0 ) +
            ((((_numbers / 10000) % 10) % 5) - (((_drawingHash / 10000) % 10) % 5) == 0 ? 1 : 0 ) +
            ((((_numbers / 100000) % 10) % 5) - (((_drawingHash / 100000) % 10) % 5) == 0 ? 1 : 0 ) +
            (((_numbers / 1000000) % 5) - ((_drawingHash / 1000000) % 5) == 0 ? 1 : 0 );

        bets[msg.sender].score = matches;

        if(matches == 2) {
            bets[msg.sender].winnings = bets[msg.sender].value * 3;
        }
        if(matches == 3) {
            bets[msg.sender].winnings = bets[msg.sender].value * 8;
        }
        if(matches == 4) {
            bets[msg.sender].winnings = bets[msg.sender].value * 34;
        }
        if(matches == 5) {
            bets[msg.sender].winnings = bets[msg.sender].value * 232;
        }
        if(matches == 6) {
            bets[msg.sender].winnings = bets[msg.sender].value * 2790;
        }
        if(matches == 7) {
            bets[msg.sender].winnings = bets[msg.sender].value * 78125;
        }

        wallets[msg.sender].balance += (bets[msg.sender].winnings + bets[msg.sender].value);

    }
}
