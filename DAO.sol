// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

/// @title <ERC20.sol>
/// @author <IvanFitro>
/* @notice <Creation of a DAO with it's own token for vote for the proposals, you can create proposals, 
           vote in the proposals, fix the time line of the proposal, recover the tokens when the propsals ends.
           Each propsal has thei own contract that custody the tokens until the proposal ends.>
*/

contract DAO {

    //----------------------------------------Initial Declarations----------------------------------------

    //Instance for the token contract 
    ERC20 private token;
    //Owner address
    address payable public owner;

    constructor()  {
        token = new ERC20(10000);
        owner = payable(msg.sender);
    }

     modifier onlyOwner {
        require(msg.sender == owner, "You don't have permisions");
        _;
    }

    struct proposal {
        string name;
        string desc;
        uint date;
        uint inFavor;
        uint against;
    }

    //Mapping to realationate the structs
    mapping (string => proposal) public Proposals;
    //Mapping to relationate the tokens contributed of a proposal
    mapping (address => mapping (string => uint)) tokensContributed;
    //Mapping to relationate a name of a propsal with their direction
    mapping (string => address) public ProposalDirection;

    //Events
    event newProposal(string, address, address);
    event Result(string, string, address);

    //----------------------------------------Token Management--------------------------------------------

    //Function to see the price of a token respect the Ether
    function tokenPrice(uint _numTokens) internal pure returns(uint) {
        return _numTokens*(1 gwei);
    }

    //Function to buy tokens
    function buyTokens(uint _numTokens) public payable {

        address payable member = payable(msg.sender);
        //Stablish the token price
        uint cost = tokenPrice(_numTokens);
        //Evaluates the money pay for the tokens
        require(msg.value >= cost, "You need more ethers.");
        //Diference that member pays
        uint returnValue = msg.value - cost;
        //The DAOs returns the quantity of tokens to the member
        member.transfer(returnValue);
        //Obtain the available tokens
        uint Balance = token.balanceOf(address(this));
        require(_numTokens <= Balance, "Buy less tokens");
        //Transfer the tokens to the client
        token.transfer(member, _numTokens);
    }

    //Function to see the available tokens in the DAO contract
    function balanceOf() public view returns(uint) {
        return token.balanceOf(address(this));
    }

    //Function to see the member tokens
    function myTokens() public view returns(uint) {
        return token.balanceOf(msg.sender);
    }

    //Function to create more tokens
    function createTokens(uint _numTokens) public onlyOwner {
        token.increaseTotalSupply(_numTokens);
    }

    //----------------------------------------DAO Management--------------------------------------------

    //Function to create a smart contract for each proposal
    function Factory(string memory _name) internal {
        address smartContractDirection = address (new ProposalContract(msg.sender));
        ProposalDirection[_name] = smartContractDirection;
        emit newProposal(_name, msg.sender, smartContractDirection);
    }


    //Function to create a proposal
    function createProposal(string memory _name, string memory _desc, uint _date) public {
        //Set the finishing date
        uint Date = block.timestamp + (_date * 86400 seconds );
        //Create the struct
        Proposals[_name] = proposal(_name, _desc, Date, 0, 0);
        //Create a smart contract
        Factory(_name);
    }

    //Function to vote in Favor/Against of a proposal
    function vote(string memory _name, string memory _action, uint _numTokens) public returns(bool) {
        require(_numTokens <= myTokens(),"You need to put less tokens");
        //Comprove that the propsal is available
        require(block.timestamp <= Proposals[_name].date, "This proposals has ended");
        //Transfer the tokens to the smart contract Proposal
        token.DAOTransfer(msg.sender, ProposalDirection[_name], _numTokens);
        //Resgister the transfer into the mapping
        tokensContributed[msg.sender][_name] = _numTokens;
        //Add the votes inFavor or Against
        if (keccak256(abi.encodePacked((_action))) == keccak256(abi.encodePacked(("inFavor")))) {
            Proposals[_name].inFavor += _numTokens; 
            return true;
        } else if (keccak256(abi.encodePacked((_action))) == keccak256(abi.encodePacked(("Against")))) {
            Proposals[_name].against += _numTokens;
            return true;
        }
        return false;
    }

    //Function to see the result of the proposal
    function seeResult(string memory _name) public returns(string memory) {
        //Comprove that the proposal has ended
        require(block.timestamp >= Proposals[_name].date, "The proposal is still active");
        string memory result;
        //See which is the final result
        if (Proposals[_name].inFavor > Proposals[_name].against) {
            result = "inFavor";
        } else if (Proposals[_name].inFavor < Proposals[_name].against) {
            result = "Against";
        } else {
            result = "Draw";
        }
        
        emit Result(_name, result, ProposalDirection[_name]);
        return result;
        
    }

    //Function to recover the tokens when the proposal finishes
    function recoverTokens(string memory _name) public returns(bool) {
        require(block.timestamp >= Proposals[_name].date, "The proposal is still active");
        //Comprove that the member participate in the proposal
        require(tokensContributed[msg.sender][_name] > 0, "You don not participate in this proposal");
        //Transfer the tokens to the smart contract Proposal to the member
        token.DAOTransfer(ProposalDirection[_name], msg.sender, tokensContributed[msg.sender][_name]);
        //Update the mapping
        tokensContributed[msg.sender][_name] -= tokensContributed[msg.sender][_name];
        return true;

    }

}

contract ProposalContract {

    address public owner;

    constructor (address _direction) {
        owner = _direction;
    }

}