// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;
import "./SafeMath.sol";

/// @title <ERC20.sol>
/// @author <IvanFitro>
/// @notice <Creation of an ERC20 token>

interface IREC20 {
    //Returns the quantity of tokens existency
    function totalSupply() external view returns(uint256);

    //Returns the quantity of tokens of an specific address
    function balanceOf(address _account) external view returns(uint256);

    //Returns the quantity of tokens that the spender can spend in the name of the owner
    function allowance(address _owner, address _spender) external view returns(uint256);

    //Returns a bool result of the indicated operation
    function transfer(address _recipient, uint256 _amount) external returns(bool);

    //Returns a bool result of the indicated operation
    function DAOTransfer(address sender, address receiver, uint256 numTokens) external returns (bool);

    //Returns a bool with the result of the spend transaction
    function approve(address _spender, uint256 _amount) external returns(bool);

    //Returns a bool with the result of the operation of transfer tokens with the allowance() method
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns(bool);

    //Event when a quantity of tokens is transfered to an origien to a destiny
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    //Event when a quantity of tokens is transfered to an origion to a destiny using the allowance() method
    event Approval(address indexed owner, address indexed spender, uint256 tokens);

}

contract ERC20 is IREC20 {

    string public constant name = "FitroDAO";
    string public constant symbol = "FDAO";
    uint8 public constant decimals = 2;
    address Owner;

    using SafeMath for uint256;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed; //allows another address to spend tokens on my behalf
    uint256 totalSupply_;

    constructor (uint256 initialSupply) {
        totalSupply_ = initialSupply;
        balances[msg.sender] = totalSupply_;
        Owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == Owner);
        _;
    }

    function totalSupply() public override view returns(uint256) {
        return totalSupply_;
    }

    function increaseTotalSupply(uint newTokensAmount) public onlyOwner {
        totalSupply_ +=newTokensAmount;
        balances[msg.sender] +=newTokensAmount;
    } 

    function balanceOf(address tokenOwner) public override view returns(uint256) {
        return balances[tokenOwner];
    }

    function allowance(address owner, address delegate) public override view returns(uint256) {
        return allowed[owner][delegate];
    }

    function transfer(address recipient, uint256 numTokens) public override returns(bool) {
        require(numTokens <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[recipient] = balances[recipient].add(numTokens);
        emit Transfer(msg.sender, recipient, numTokens);
        return true;
    }

    function DAOTransfer(address sender, address receiver, uint256 numTokens) public override returns (bool){
        require(numTokens <= balances[sender]);
        balances[sender] = balances[sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(sender,receiver,numTokens);
        return true;
    } 

    function approve(address delegate, uint256 numTokens) public override returns(bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns(bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

}