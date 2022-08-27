// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC1155Drop.sol";
import "@thirdweb-dev/contracts/extension/interface/IBurnableERC1155.sol";

/**
 * @title CatAttackNFT - The game contract for https://catattacknft.vercel.app/
 */
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

    /** 
     * @notice Claim a kitten to start playing, but only if you don't already own a cat
     */
    function claimKitten() external {
        require(isGamePaused == false, "GAME_PAUSED");
        require(balanceOf[msg.sender][0] == 0, "Already got a Kitten");
        require(balanceOf[msg.sender][1] == 0, "Already got a Grumpy cat");
        require(balanceOf[msg.sender][2] == 0, "Already got a Ninja cat");
        _mint(msg.sender, 0, 1, "");
        // claiming a Kitten enters the game at level 1
        emit LevelUp(msg.sender, 1);
    }

    /** 
     * @notice Transfer cats to level up
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override gameNotPaused {
        // can only transfer kittens
        require(id == 0, "This cat is not transferable!");
        super.safeTransferFrom(from, to, id, amount, data);
        if(from != to && id == 0) {
            // transfering level 1 NFT gives you a level 2 NFT
            _mint(from, 1, 1, "");
            emit LevelUp(to, 1); // receiver levels up to 1
            emit LevelUp(from, 2); // sender levels up to 2
        }
    }

    /** 
     * @notice Burn a cat to either level up or attack another cat
     */
    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) external override gameNotPaused {
        // the owner can burn their NFT, but any ninja cat owner can also burn anyone else's NFT
        require(msg.sender == account || balanceOf[msg.sender][2] > 0, "NOT_TOKEN_OWNER or ninja cat");
        _burn(account, id, amount);
        if(id == 1) {
            // burning level 2 NFT gives you a level 3 NFT
            _mint(account, 2, 1, "");
            emit LevelUp(account, 3);
        }
    }

    /**
     * @notice Lets a Ninja cat owner attack another user's to burn their cats
     */
    function attack(address victim) external gameNotPaused {
        // only a ninja cat owner can attack
        require(balanceOf[msg.sender][2] > 0, "You need a ninja cat to attack!");
        // find which cat the victim has
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
        // burn it
        _burn(victim, tokenToBurn, 1);
        emit Miaowed(msg.sender, victim, tokenToBurn + 1);
    }
    
    /** 
     * @notice Lets the owner restart the game
     */
    function startGame() external {
        require(msg.sender == owner(), "Only owner can start the game");
        isGamePaused = false;
    }

    /** 
     * @notice Lets the owner pause the game
     */
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