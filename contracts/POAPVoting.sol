//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IPOAP {
    function tokenEvent(uint256 tokenId) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);
}

contract POAPVoting is ERC721 {
    event Vote(address voter, address indexed to);
    event Winner(address winner);

    address public poap;
    uint256 public eventId;

    uint256 public votingDeadline;
    bool public mintedWinners;

    mapping(address => bool) private _voted;
    mapping(address => uint256) public votes;

    mapping(address => bool) private _hasBeenVoted;
    address[] private _votedAttendees;

    constructor(
        address _poap,
        uint256 _eventId,
        uint256 _votingDeadline,
        string memory _nftName,
        string memory _nftSymbol
    ) ERC721(_nftName, _nftSymbol) {
        poap = _poap;
        eventId = _eventId;
        votingDeadline = _votingDeadline;
    }

    modifier attended(uint256 poapTokenId) {
        require(
            IPOAP(poap).ownerOf(poapTokenId) == msg.sender,
            "Caller is not POAP owner"
        );
        require(
            IPOAP(poap).tokenEvent(poapTokenId) == eventId,
            "Invalid POAP event"
        );
        _;
    }

    function vote(uint256 poapTokenId, address attendeeToVote)
        public
        attended(poapTokenId)
    {
        require(!_voted[msg.sender], "Caller has already voted");
        require(block.timestamp < votingDeadline, "Voting has already ended");

        if (!_hasBeenVoted[attendeeToVote]) {
            _hasBeenVoted[attendeeToVote] = true;
            _votedAttendees.push(attendeeToVote);
        }

        votes[attendeeToVote]++;

        emit Vote(msg.sender, attendeeToVote);
    }

    function mintWinners() public {
        require(block.timestamp > votingDeadline, "Voting has not ended yet");
        require(!mintedWinners, "NFT has already been minted");

        uint256 maxVotes = _maxVotes();

        for (uint256 i = 0; i < _votedAttendees.length; i++) {
            address _attendee = _votedAttendees[i];

            if (votes[_attendee] == maxVotes) _mint(_attendee, i);

            emit Winner(_attendee);
        }

        mintedWinners = true;
    }

    function _maxVotes() private view returns (uint256) {
        uint256 _max = 0;

        for (uint256 i = 0; i < _votedAttendees.length; i++) {
            uint256 _votes = votes[_votedAttendees[i]];
            if (_votes > _max) _max = _votes;
        }

        return _max;
    }
}
