// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC1155Drop.sol";
import "@thirdweb-dev/contracts/extension/interface/IBurnableERC1155.sol";

contract CatAttackNFT is ERC1155Drop, IBurnableERC1155 {

    event LevelUp(address indexed account, uint256 level);
    event Miaowed(address indexed attacker, address indexed victim, uint256 level);

    bool public isGamePaused = false;

    constructor(
        string memory _name,
        string memory _symbol
    )
        ERC1155Drop(
            _name,
            _symbol,
            msg.sender,
            0,
            msg.sender
        )
    {}

    function _beforeClaim(
        uint256 _tokenId,
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        AllowlistProof calldata _allowlistProof,
        bytes memory _data
    ) internal override view gameNotPaused {
        super._beforeClaim(
            _tokenId,
            _receiver,
            _quantity,
            _currency,
            _pricePerToken,
            _allowlistProof,
            _data
        );
        require(balanceOf[msg.sender][0] == 0, "Already got a cat");
        require(balanceOf[msg.sender][1] == 0, "Already got a cat");
        require(balanceOf[msg.sender][2] == 0, "Already got a cat");
    }

    function transferTokensOnClaim(
        address _to,
        uint256 _tokenId,
        uint256 _quantityBeingClaimed
    ) internal override {
        super.transferTokensOnClaim(_to, _tokenId, _quantityBeingClaimed);
        if(_tokenId == 0) {
            // claiming a NFTs enters the game at level 1
            emit LevelUp(_to, 1);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override gameNotPaused {
        super.safeTransferFrom(from, to, id, amount, data);
        if(from != to && id == 0) {
            // transfering level 1 NFT gives you a level 2 NFT
            _mint(from, 1, 1, "");
            emit LevelUp(to, 1);
            emit LevelUp(from, 2);
        }
        if(id > 0) {
            revert("This cat is not transferable!");
        }
    }

    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) external override gameNotPaused {
        require(msg.sender == account || balanceOf[msg.sender][2] > 0, "NOT_TOKEN_OWNER or ninja cat");
        _burn(account, id, amount);
        if(id == 1) {
            // burning level 2 NFT gives you a level 3 NFT
            _mint(account, 2, 1, "");
            emit LevelUp(account, 3);
        }
    }

    function attack(address victim) external gameNotPaused {
        require(balanceOf[msg.sender][2] > 0, "You need a ninja cat to attack!");
        uint256 tokenToBurn = 0;
        if(balanceOf[victim][0] > 0) {
            tokenToBurn = 0;
        } else if(balanceOf[victim][1] > 0) {
            tokenToBurn = 1;
        } else if(balanceOf[victim][2] > 0) {
            tokenToBurn = 2;
        } else {
            revert("Victim has no cat!");
        }
        _burn(victim, tokenToBurn, 1);
        emit Miaowed(msg.sender, victim, tokenToBurn + 1);
    }
    
    
    function startGame() external {
        require(msg.sender == owner(), "Only owner can start the game");
        isGamePaused = false;
    }

    function stopGame() external {
        require(msg.sender == owner(), "Only owner can stop the game");
        isGamePaused = true;
    }

    modifier gameNotPaused() {
        require(!isGamePaused, "Game is paused");
        _;
    }

    /// @dev Lets a token owner burn multiple tokens they own at once (i.e. destroy for good)
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external override {
        revert("not implemented");
    }
}