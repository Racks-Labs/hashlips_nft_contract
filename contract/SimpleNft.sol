// SPDX-License-Identifier: MIT

// Amended by HashLips
/**
		!Disclaimer!
		These contracts have been used to create tutorials,
		and was created for the purpose to teach people
		how to create smart contracts on the blockchain.
		please review this code on your own before using any of
		the following code for production.
		HashLips will not be liable in any way if for the use
		of the code. That being said, the code has been tested
		to the best of the developers' knowledge to work as intended.
*/

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721Enumerable, Ownable {
	using Strings for uint256;

	string baseURI;
	string public baseExtension = ".json";
	uint256 public cost = 0.05 ether;
	uint256 public currentSupply;
	uint256 public maxSupply;
	//uint256 public maxMintAmount = 20;
	bool public paused = false;
	bool public revealed = false;
	string public notRevealedUri;
	uint256[] tokensAssigned;
	address previousContract;

	constructor(
		string memory _name,
		string memory _symbol,
		string memory _initBaseURI,
		string memory _initNotRevealedUri,
		uint256 _initialSupply,
		uint256 _maxSupply,
		address _previousContract
	) ERC721(_name, _symbol) {
		setBaseURI(_initBaseURI);
		setNotRevealedURI(_initNotRevealedUri);
		currentSupply = _initialSupply;
		maxSupply = _maxSupply;
		previousContract = _previousContract;
	}

	// internal
	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	function random(uint256 range) internal view returns (uint256) {
		return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, totalSupply()))) % range;
	}

	function setValidRandom() public view returns (uint256){
		uint256 rnd_num = random(currentSupply);
		uint256 r;
		uint256 i;

		r = rnd_num + 1;
		while (r != rnd_num){
			for (i = 0; i < tokensAssigned.length; i++){
				if (tokensAssigned[i] == r)
					break;
			}
			if (i == tokensAssigned.length){
				return r;
			}
			r++;
			if (r == currentSupply)
				r = 0;
		}
		return r;
	}

	// public
	function setCurrentSupply(uint256 n) public onlyOwner{
		require(n > currentSupply, "Usted es comunista porque es tonto o es tonto porque es comunista?");
		require(totalSupply() + n <= maxSupply, "No somos bolivarianos!");
		currentSupply = n;
	}

	function mint(uint256 _mintAmount) public payable {
		uint256 supply = totalSupply();
		uint256 rnd_num;

		require(!paused);
		require(_mintAmount > 0);
		//require(_mintAmount <= maxMintAmount);
		require(supply + _mintAmount <= maxSupply);
		require(tokensAssigned.length <= currentSupply);

		if (msg.sender != owner()) {
			if (walletOfOwner(msg.sender).length() < previousContract.call(abi.encodeWithSignature("walletOfOwner(address)", msg.sender))) //Llamar a walletOfOwner() en previous contract
				require(msg.value >= previousContract.call(abi.encodeWithSignature("cost")) * _mintAmount);	//Llamar a cost() en previous contract;
			else
				require(msg.value >= cost * _mintAmount);
		}

		for (uint256 i = 1; i <= _mintAmount; i++) {
			rnd_num = setValidRandom();

			tokensAssigned.push(rnd_num);
			_safeMint(msg.sender, supply + i);
		}
	}

	function getTokenAssigned(uint256 _num) public view returns (uint256){
		require(_num< tokensAssigned.length);
		return tokensAssigned[_num];
	}

	function walletOfOwner(address _owner)
		public
		view
		returns (uint256[] memory)
	{
		uint256 ownerTokenCount = balanceOf(_owner);
		uint256[] memory tokenIds = new uint256[](ownerTokenCount);
		for (uint256 i; i < ownerTokenCount; i++) {
			tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
		}
		return tokenIds;
	}

	function tokenURI(uint256 tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		require(
			_exists(tokenId) && tokenId <= totalSupply() ,
			"ERC721Metadata: URI query for nonexistent token"
		);

		if(revealed == false) {
				return notRevealedUri;
		}

		string memory currentBaseURI = _baseURI();

		return bytes(currentBaseURI).length > 0
				? string(abi.encodePacked(currentBaseURI, (tokensAssigned[tokenId - 1]).toString(), baseExtension))
				: "";
	}

	//only owner
	function reveal() public onlyOwner {
			revealed = true;
	}

	function setCost(uint256 _newCost) public onlyOwner {
		cost = _newCost;
	}

	/*function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
		maxMintAmount = _newmaxMintAmount;
	}*/

	function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
		notRevealedUri = _notRevealedURI;
	}

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
		baseExtension = _newBaseExtension;
	}

	function pause(bool _state) public onlyOwner {
		paused = _state;
	}

	function withdraw() public payable onlyOwner {

		// =============================================================================
		(bool os, ) = payable(owner()).call{value: address(this).balance}("");
		require(os);
		// =============================================================================
	}
}
