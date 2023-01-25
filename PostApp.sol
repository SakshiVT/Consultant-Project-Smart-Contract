// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract SocialMedia {

    struct Post {
        uint id;
        address author;
        string content;
        uint timestamp;
        bool isCensored;
        string imageURL;
    }

    mapping (uint => mapping (address => bool)) public likes;
    mapping (uint => mapping (address => string)) public comments;

    uint256 public numPosts; // number of posts on the deso.
    mapping(uint256 => Post) public posts; // storse all posts on the deso.
    mapping (address => Post[]) public userPosts; // stores all posts on the deso by a particular user.
    mapping (address => uint[]) public postIds; // stores the no. of posts on the deso by a particular user.
    //mapping (address => bool) public isModerator; // stores whether a particular address is a moderator or not.
    address public owner; // stores the address of the owner of this contract.
    mapping (address => uint) public scores; //scores of all users

    event NewPost(uint postId, address author, string content, uint timestamp, bool isCensored, string imageURL);
    event NewLike(address postAuthor, address likedBy, uint256 postId, bool like, uint256 authorScore);
    event NewComment(address postAuthor, address commentedBy, uint256 postId, string content, uint256 authorScore);
    event DeleteComment(address postAuthor, address commentBy, uint256 postId, uint256 authorScore);
    event DeletePost(uint postId, address postAuthor);
    event EditPost(uint postId, address author, string content, uint timestamp, bool isCensored, string imageURL);

    event CensoredPost(address postAuthor, uint postld);
    event UncensoredPost(address postAuthor, uint postld);

    
    constructor() {
        owner = msg.sender;
    }

    function createPost(string memory _content,string memory _imageURL, bool _isCensored) public {
        uint256 time = block.timestamp;
        uint postId = numPosts;
        Post memory post = Post(postId, msg.sender, _content, time, _isCensored, _imageURL);
        userPosts[msg.sender].push(post);
        posts[postId] = post;
        scores[msg.sender] += 10;

        //setting postCount mapping
        postIds[msg.sender].push(postId);
        numPosts++;    
        emit NewPost(postId, msg.sender, _content, time, _isCensored, _imageURL);      
    }


    function likePost(address _postAuthor, uint _postld) public checkPostId(_postAuthor, _postld) {
        if(likes[_postld][msg.sender]){
            likes[_postld][msg.sender] = false;
            scores[_postAuthor] -= 5;
        } else{
            likes[_postld][msg.sender] = true;
            scores[_postAuthor] += 5;
        }
        emit NewLike(_postAuthor, msg.sender, _postld, likes[_postld][msg.sender], scores[_postAuthor]);
    }

    function commentOnPost(address _postAuthor, uint _postld, string memory _content) public checkPostId(_postAuthor, _postld) {
        comments[_postld][msg.sender] = _content;
        scores[_postAuthor] += 10;
        emit NewComment(_postAuthor, msg.sender, _postld, _content, scores[_postAuthor]);
    }

    function deleteComment(address _postAuthor, uint _postId) public checkPostId(_postAuthor, _postId) {
        delete comments[_postId][msg.sender];
        scores[_postAuthor] -= 10;
        emit DeleteComment(_postAuthor, msg.sender, _postId, scores[_postAuthor]);
    }

    function deletePost(uint256 _postId) public checkPostId(msg.sender, _postId){
        for(uint i = 0; i<userPosts[msg.sender].length ; i++){
            if(userPosts[msg.sender][i].id == _postId){
                delete userPosts[msg.sender][i];
                break;
            }
        }
        delete posts[_postId];
        emit DeletePost(_postId, msg.sender);
    }

    function editPost(uint256 _postId, string memory _content,string memory _imageURL, bool _isCensored) public checkPostId(msg.sender, _postId){
        uint256 time = block.timestamp;
        for(uint i = 0; i<userPosts[msg.sender].length ; i++){
            if(userPosts[msg.sender][i].id == _postId){
                userPosts[msg.sender][i].content = _content;
                userPosts[msg.sender][i].timestamp = time;
                userPosts[msg.sender][i].isCensored = _isCensored;
                userPosts[msg.sender][i].imageURL = _imageURL;
            }
        }
        posts[_postId].content = _content;
        posts[_postId].timestamp = time;
        posts[_postId].isCensored = _isCensored;
        posts[_postId].imageURL = _imageURL;
        emit EditPost(_postId, msg.sender, _content, time, _isCensored, _imageURL);
    }
    
    function getPosts() internal view returns (Post[] storage) {
        return userPosts[msg.sender];
    }

    function getPostById(uint256 _postId) public view returns(Post memory){
        return posts[_postId];
    }

    function getPostCount(address user) public view returns (uint) {
        return postIds[user].length;
    }

    function leaderboard() public{
        // return scores
    }
    
    function censorPost(address postAuthor, uint postld) public  {
        //require(postld < postCount[postAuthor], "Invalid post ID.");
        require(!userPosts[postAuthor][postld].isCensored, "Post is already censored.");
        userPosts [postAuthor][postld].isCensored = true;
        emit CensoredPost(postAuthor, postld);
    }

    function uncensorPost(address postAuthor, uint postld) public {
        //require(postld < postCount[postAuthor], "Invalid post ID.");
        require(userPosts[postAuthor][postld].isCensored, "Post is not censored.");
        userPosts [postAuthor][postld].isCensored = false;
        emit UncensoredPost(postAuthor, postld);
    }
    // access control
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier checkPostId(address _postAuthor, uint _postld) {

        require(posts[_postld].author == _postAuthor, "Invaild post!!");
        _;
    }



}
