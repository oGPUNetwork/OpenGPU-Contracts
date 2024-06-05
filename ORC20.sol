// SPDX-License-Identifier: CC0
pragma solidity ^0.8.0;

contract ORC20 {
    // Token metadata struct
    struct Metadata {
        string description;
        string logoUri;
        string projectGif;
        string projectEmoji;
        mapping(string => string) socials;
        string[] socialKeys;
    }

    Metadata private _metadata;
    
    // Owner address for access control
    address private _owner;

    // Token details
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    // Balances and allowances
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Active pairs for trading
    mapping(address => bool) private _activePairs;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event MetadataUpdated(string key, string value);
    event ActivePairsUpdated(address indexed pair, bool isActive);
    event Swap(
        address indexed maker, 
        bool swapType, 
        uint256 tokenAmount, 
        string description,
        string logoUri,
        string projectGif,
        string projectEmoji,
        string[] socialPlatforms,
        string[] socialUris
    );
    event NewORC20Created(
        string name,
        string symbol,
        uint8 decimals,
        uint256 totalSupply,
        string description,
        string logoUri,
        string projectGif,
        string projectEmoji,
        string[] socialPlatforms,
        string[] socialUris
    );

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    // Constructor
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply,
        string memory description_,
        string memory logoUri_,
        string memory projectGif_,
        string memory projectEmoji_,
        string[] memory socialPlatforms,
        string[] memory socialUris
    ) {
        require(socialPlatforms.length == socialUris.length, "Social platforms and URIs length mismatch");

        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = initialSupply * 10 ** uint256(_decimals);
        _balances[msg.sender] = _totalSupply;
        _owner = msg.sender;

        _metadata.description = description_;
        _metadata.logoUri = logoUri_;
        _metadata.projectGif = projectGif_;
        _metadata.projectEmoji = projectEmoji_;

        for (uint256 i = 0; i < socialPlatforms.length; i++) {
            _metadata.socials[socialPlatforms[i]] = socialUris[i];
            _metadata.socialKeys.push(socialPlatforms[i]);
        }

        emit NewORC20Created(
            name_,
            symbol_,
            decimals_,
            _totalSupply,
            description_,
            logoUri_,
            projectGif_,
            projectEmoji_,
            socialPlatforms,
            socialUris
        );
    }

    // Standard ERC-20 methods
    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) external view returns (uint256 balance) {
        return _balances[owner];
    }

    function transfer(address to, uint256 value) external returns (bool success) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool success) {
        require(_allowances[from][msg.sender] >= value, "Allowance exceeded");
        _allowances[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool success) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256 remaining) {
        return _allowances[owner][spender];
    }

    // ORC-20 specific methods
    function getMetadata() external view returns (
        string memory description,
        string memory logoUri,
        string memory projectGif,
        string memory projectEmoji,
        string[] memory socialPlatforms,
        string[] memory socialUris
    ) {
        socialPlatforms = new string[](_metadata.socialKeys.length);
        socialUris = new string[](_metadata.socialKeys.length);

        for (uint256 i = 0; i < _metadata.socialKeys.length; i++) {
            socialPlatforms[i] = _metadata.socialKeys[i];
            socialUris[i] = _metadata.socials[_metadata.socialKeys[i]];
        }

        return (
            _metadata.description,
            _metadata.logoUri,
            _metadata.projectGif,
            _metadata.projectEmoji,
            socialPlatforms,
            socialUris
        );
    }

    function getSocials(string memory platform) external view returns (string memory) {
        return _metadata.socials[platform];
    }

    function setDescription(string memory newDescription) external onlyOwner {
        _metadata.description = newDescription;
        emit MetadataUpdated("description", newDescription);
    }

    function setLogo(string memory newLogoUri) external onlyOwner {
        _metadata.logoUri = newLogoUri;
        emit MetadataUpdated("logoUri", newLogoUri);
    }

    function setSocials(string memory platform, string memory uri) external onlyOwner {
        if (bytes(_metadata.socials[platform]).length == 0) {
            _metadata.socialKeys.push(platform);
        }
        _metadata.socials[platform] = uri;
        emit MetadataUpdated(string(abi.encodePacked("socials_", platform)), uri);
    }

    function setActivePairs(address pair, bool isActive) external onlyOwner {
        _activePairs[pair] = isActive;
        emit ActivePairsUpdated(pair, isActive);
    }

    function setProjectGif(string memory newGifUri) external onlyOwner {
        _metadata.projectGif = newGifUri;
        emit MetadataUpdated("projectGif", newGifUri);
    }

    function setProjectEmoji(string memory newEmoji) external onlyOwner {
        _metadata.projectEmoji = newEmoji;
        emit MetadataUpdated("projectEmoji", newEmoji);
    }

    // Internal transfer function with active pairs logic
    function _transfer(address from, address to, uint256 value) internal {
        require(_balances[from] >= value, "Insufficient balance");
        
        bool isBuy = _activePairs[from];
        bool isSell = _activePairs[to];

        _balances[from] -= value;
        _balances[to] += value;

        if (isBuy || isSell) {
            string[] memory socialPlatforms = new string[](_metadata.socialKeys.length);
            string[] memory socialUris = new string[](_metadata.socialKeys.length);

            for (uint256 i = 0; i < _metadata.socialKeys.length; i++) {
                socialPlatforms[i] = _metadata.socialKeys[i];
                socialUris[i] = _metadata.socials[_metadata.socialKeys[i]];
            }

            emit Swap(
                from,
                isBuy,
                value,
                _metadata.description,
                _metadata.logoUri,
                _metadata.projectGif,
                _metadata.projectEmoji,
                socialPlatforms,
                socialUris
            );
        }

        emit Transfer(from, to, value);
    }
}


contract TestToken is ORC20 {
    constructor() ORC20("Test Token", "TEST", 18, 1000000, "Test token for ORC-20", "", "", "", new string[](0), new string[](0)) {
    }
}
