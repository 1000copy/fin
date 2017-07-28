import UIKit
import Alamofire
import Ji
class MemberModel: NSObject ,BaseHtmlModelProtocol{
    enum BlockState {
        case blocked
        case unBlocked
    }
    enum FollowState {
        case followed
        case unFollowed
    }
    var avata: String?
    var userId:String?
    var userName:String?
    var introduce:String?
    var blockState:BlockState = .unBlocked
    var followState:FollowState = .unFollowed
    var userToken:String?
    var topics:[MemberTopicsModel] = []
    var replies:[MemberRepliesModel] = []
    required init(rootNode: JiNode) {
        self.avata = rootNode.xPath("./td[1]/img").first?["src"]
        self.userName = rootNode.xPath("./td[3]/h1").first?.content
        self.introduce = rootNode.xPath("./td[3]/span[1]").first?.content
        // follow状态
        if let followNode = rootNode.xPath("./td[3]/div[1]/input[1]").first
            , let followStateClickUrl = followNode["onclick"] , followStateClickUrl.Lenght > 0{
            var index = followStateClickUrl.range(of: "'")
            var url = followStateClickUrl.substring(from: index!.upperBound)
            url = url.substring(to:url.index(url.endIndex, offsetBy: -2))
            if url.hasPrefix("/follow"){
                self.followState = .unFollowed
            }
            else{
                self.followState = .followed
            }
            index = url.range(of: "?t=")
            // comment 3 lines by TJ
//            self.userToken = url.substring(from: index!.upperBound)
//            //UserId
//            let startIndex = url.range(of:"/", options: .backwards, range: nil, locale: nil)
//            self.userId = url.substring(with: Range<String.Index>( startIndex!.upperBound ..< index!.lowerBound))
        }
        // block状态
        if let followNode = rootNode.xPath("./td[3]/div[1]/input[2]").first
            , let followStateClickUrl = followNode["onclick"] , followStateClickUrl.Lenght > 0{
            let index = followStateClickUrl.range(of: "unblock")
            if index == nil{
                self.blockState = .unBlocked
            }
            else{
                self.blockState = .blocked
            }
        }
    }
}
class MemberTopicsModel: TopicListModel {
    init(memberTopicRootNode:JiNode){
        super.init()
        self.nodeName = memberTopicRootNode.xPath("./table/tr/td[1]/span[1]/a[1]").first?.content
        self.userName = memberTopicRootNode.xPath("./table/tr/td[1]/span[1]/strong[1]/a[1]")[0].content
        let node = memberTopicRootNode.xPath("./table/tr/td[1]/span[2]/a[1]")[0]
        self.topicTitle = node.content
        var topicIdUrl = node["href"];
        if var id = topicIdUrl {
            if let range = id.range(of: "/t/") {
                id.replaceSubrange(range, with: "")
            }
            if let range = id.range(of: "#") {
                id = id.substring(to: range.lowerBound)
                topicIdUrl = id
            }
        }
        self.topicId = topicIdUrl
        self.date = memberTopicRootNode.xPath("./table/tr/td[1]/span[3]")[0].content
        var lastReplyUserName:String? = nil
        if let lastReplyUser = memberTopicRootNode.xPath("./table/tr/td[1]/span[3]/strong[1]/a[1]").first{
            lastReplyUserName = lastReplyUser.content
        }
        self.lastReplyUserName = lastReplyUserName
        var replies:String? = nil;
        if let reply = memberTopicRootNode.xPath("./table/tr/td[2]/a[1]").first {
            replies = reply.content
        }
        self.replies  = replies
    }
}
class MemberRepliesModel: NSObject ,BaseHtmlModelProtocol{
    var topicId: String?
    var date: String?
    var title: String?
    var reply: String?
    required init(rootNode: JiNode) {
        let node = rootNode.xPath("./table/tr/td[1]/span[1]/a[1]")[0]
        self.title = node.content
        var topicIdUrl = node["href"];
        if var id = topicIdUrl {
            if let range = id.range(of: "/t/") {
                id.replaceSubrange(range, with: "")
            }
            if let range = id.range(of: "#") {
                id = id.substring(to: range.lowerBound)
                topicIdUrl = id
            }
        }
        self.topicId = topicIdUrl
        self.date = rootNode.xPath("./table/tr/td/div/span")[0].content
    }
}
class MemberModelHTTP {
    class func getMemberInfo(_ username:String , completionHandler: ((V2ValueResponse<MemberModel>) -> Void)? = nil) {
        let url = V2EXURL + "member/" + username
        Alamofire.request(url, headers: MOBILE_CLIENT_HEADERS).responseJiHtml { (response) -> Void in
            if let jiHtml = response.result.value {
                if let aRootNode = jiHtml.xPath("//*[@id='Wrapper']/div/div[1]/div[1]/table/tr")?.first{
                    let member = MemberModel(rootNode: aRootNode);
                    if let rootNodes = jiHtml.xPath("//*[@class='cell item']") {
                        for rootNode  in rootNodes {
                            member.topics.append(MemberTopicsModel(memberTopicRootNode:rootNode))
                        }
                    }
                    if let rootNodes = jiHtml.xPath("//*[@class='dock_area']") {
                        for rootNode in rootNodes {
                            let replyModel = MemberRepliesModel(rootNode:rootNode)
                            if  let replyNode = rootNode.nextSibling {
                                replyModel.reply = replyNode.xPath("./div").first?.content
                            }
                            member.replies.append(replyModel)
                        }
                    }
                    completionHandler?(V2ValueResponse(value: member, success: true))
                }
            }
            completionHandler?(V2ValueResponse(success: false))
        }
    }
    class func follow(_ userId:String,
                      userToken:String,
                      type:MemberModel.FollowState,
                      completionHandler: ((V2Response) -> Void)?
        ){
        let action = type == .followed ? "follow/" : "unfollow/"
        let url = V2EXURL + action + userId + "?t=" + userToken
        Alamofire.request(url, headers: MOBILE_CLIENT_HEADERS).responseJiHtml { (response) in
            completionHandler?(V2Response(success: response.result.isSuccess))
        }
    }
    class func block(_ userId:String,
                     userToken:String,
                     type:MemberModel.BlockState,
                     completionHandler: ((V2Response) -> Void)?
        ){
        let action = type == .blocked ? "block/" : "unblock/"
        let url = V2EXURL + action + userId + "?t=" + userToken
        Alamofire.request(url, headers: MOBILE_CLIENT_HEADERS).responseJiHtml { (response) in
            completionHandler?(V2Response(success: response.result.isSuccess))
        }
    }
}
