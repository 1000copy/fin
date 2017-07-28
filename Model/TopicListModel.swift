import UIKit
import ObjectMapper
import Alamofire
import Ji
import YYText
class TopicListModel:NSObject {
    var topicId: String?
    var avata: String?
    var nodeName: String?
    var userName: String?
    var topicTitle: String?
    var topicTitleAttributedString: NSMutableAttributedString?
    private var topicTitleLayout: YYTextLayout?
    func getHeight()-> CGFloat?{
        return (self.topicTitleLayout?.textBoundingRect.size.height)
    }
    var date: String?
    var lastReplyUserName: String?
    var replies: String?
    func toDict()->TableDataSourceItem{
        var item :  TableDataSourceItem  = TableDataSourceItem()
        item["topicId"] = topicId
        item["avata"] = avata
        item["nodeName"] = nodeName
        item["userName"] = userName
        item["topicTitle"] = topicTitle
        item["topicTitleAttributedString"] = topicTitleAttributedString
        item["topicTitleLayout"] = topicTitleLayout
        item["date"] = date
        item["lastReplyUserName"] = lastReplyUserName
        item["replies"] = replies
        return item
    }
    func fromDict(_ item:TableDataSourceItem){
        //        var item :  TableDataSourceItem  = TableDataSourceItem()
        topicId = item["topicId"] as? String
        avata = item["avata"] as? String
        nodeName = item["nodeName"] as? String
        userName = item["userName"] as? String
        topicTitle = item["topicTitle"] as? String
        topicTitleAttributedString = item["topicTitleAttributedString"] as? NSMutableAttributedString
        topicTitleLayout = item["topicTitleLayout"] as? YYTextLayout
        date = item["date"] as? String
        lastReplyUserName = item["lastReplyUserName"] as? String
        replies = item["replies"] as? String
    }
    var hits: String?
    override init() {
        super.init()
    }
    init(rootNode: JiNode) {
        super.init()
        self.avata = rootNode.xPath("./table/tr/td[1]/a[1]/img[@class='avatar']").first?["src"]
        self.nodeName = rootNode.xPath("./table/tr/td[3]/span[1]/a[1]").first?.content
        self.userName = rootNode.xPath("./table/tr/td[3]/span[1]/strong[1]/a[1]").first?.content
        let node = rootNode.xPath("./table/tr/td[3]/span[2]/a[1]").first
        self.topicTitle = node?.content
        self.setupTitleLayout()
        var topicIdUrl = node?["href"];
        if var id = topicIdUrl {
            if let range = id.range(of: "/t/") {
                id.replaceSubrange(range, with: "");
            }
            if let range = id.range(of: "#") {
                id = id.substring(to: range.lowerBound)
                topicIdUrl = id
            }
        }
        self.topicId = topicIdUrl
        self.date = rootNode.xPath("./table/tr/td[3]/span[3]").first?.content
        var lastReplyUserName:String? = nil
        if let lastReplyUser = rootNode.xPath("./table/tr/td[3]/span[3]/strong[1]/a[1]").first{
            lastReplyUserName = lastReplyUser.content
        }
        self.lastReplyUserName = lastReplyUserName
        var replies:String? = nil;
        if let reply = rootNode.xPath("./table/tr/td[4]/a[1]").first {
            replies = reply.content
        }
        self.replies  = replies
    }
    init(favoritesRootNode:JiNode) {
        super.init()
        self.avata = favoritesRootNode.xPath("./table/tr/td[1]/a[1]/img[@class='avatar']").first?["src"]
        self.nodeName = favoritesRootNode.xPath("./table/tr/td[3]/span[2]/a[1]").first?.content
        self.userName = favoritesRootNode.xPath("./table/tr/td[3]/span[2]/strong[1]/a").first?.content
        let node = favoritesRootNode.xPath("./table/tr/td[3]/span/a[1]").first
        self.topicTitle = node?.content
        self.setupTitleLayout()
        var topicIdUrl = node?["href"];
        if var id = topicIdUrl {
            if let range = id.range(of: "/t/") {
                id.replaceSubrange(range, with: "");
            }
            if let range = id.range(of: "#") {
                id = id.substring(to: range.lowerBound)
                topicIdUrl = id
            }
        }
        self.topicId = topicIdUrl
        let date = favoritesRootNode.xPath("./table/tr/td[3]/span[2]").first?.content
        if let date = date {
            let array = date.components(separatedBy: "•")
            if array.count == 4 {
                self.date = array[3].trimmingCharacters(in: NSCharacterSet.whitespaces)
            }
        }
        self.lastReplyUserName = favoritesRootNode.xPath("./table/tr/td[3]/span[2]/strong[2]/a[1]").first?.content
        self.replies = favoritesRootNode.xPath("./table/tr/td[4]/a[1]").first?.content
    }
    init(nodeRootNode:JiNode) {
        super.init()
        self.avata = nodeRootNode.xPath("./table/tr/td[1]/a[1]/img[@class='avatar']").first?["src"]
        self.userName = nodeRootNode.xPath("./table/tr/td[3]/span[2]/strong").first?.content
        let node = nodeRootNode.xPath("./table/tr/td[3]/span/a[1]").first
        self.topicTitle = node?.content
        self.setupTitleLayout()
        var topicIdUrl = node?["href"];
        if var id = topicIdUrl {
            if let range = id.range(of: "/t/") {
                id.replaceSubrange(range, with: "");
            }
            if let range = id.range(of: "#") {
                id = id.substring(to: range.lowerBound)
                topicIdUrl = id
            }
        }
        self.topicId = topicIdUrl
        self.hits = nodeRootNode.xPath("./table/tr/td[3]/span[last()]/text()").first?.content
        if var hits = self.hits {
            hits = hits.substring(from: hits.index(hits.startIndex, offsetBy: 5))
            self.hits = hits
        }
        var replies:String? = nil;
        if let reply = nodeRootNode.xPath("./table/tr/td[4]/a[1]").first {
            replies = reply.content
        }
        self.replies  = replies
    }
    func setupTitleLayout(){
        if let title = self.topicTitle {
            self.topicTitleAttributedString = NSMutableAttributedString(string: title,
                                                                        attributes: [
                                                                            NSFontAttributeName:v2Font(17),
                                                                            NSForegroundColorAttributeName:V2EXColor.colors.v2_TopicListTitleColor,
                                                                            ])
            self.topicTitleAttributedString?.yy_lineSpacing = 3
            if let str = self.topicTitleAttributedString {
                str.yy_color = V2EXColor.colors.v2_TopicListTitleColor
                self.topicTitleLayout = YYTextLayout(containerSize: CGSize(width: SCREEN_WIDTH-24, height: 9999), text: str)
            }
        }
    }
}
class TJHttp{
    let V2EXURL = "https://www.v2ex.com/"
    let USER_AGENT = "Mozilla/5.0 (iPhone; CPU iPhone OS 8_0 like Mac OS X) AppleWebKit/600.1.3 (KHTML, like Gecko) Version/8.0 Mobile/12A4345d Safari/600.1.4";
    var MOBILE_CLIENT_HEADERS : [String:String] = [:]
    @discardableResult
    public func responseNode(_ url: String,_ parameters: Parameters? = nil,_ xpath:String,
                             completionHandler:@escaping (Ji,JiNode?,[JiNode]?,Bool) -> Void){
        responseJi(url,parameters){response in
            if  let jiHtml = response.result.value{
                if let aRootNode = jiHtml.xPath(xpath){
                    completionHandler(jiHtml,jiHtml.rootNode, aRootNode,response.result.isSuccess)
                }
            }
        }
    }
    public func responseJi(_ url: String,_ parameters: Parameters? = nil,completionHandler:@escaping (DataResponse<Ji>) -> Void){
        var href = url
        if !url.hasPrefix("https://"){
            href = V2EXURL + url
        }
        let dr = Alamofire.request(href,parameters: parameters, headers: MOBILE_CLIENT_HEADERS)
        dr.response(responseSerializer: Alamofire.DataRequest.JIHTMLResponseSerializer(), completionHandler: completionHandler);
    }
    public func request(_ url: String,_ parameters: Parameters? = nil)-> DataRequest{
        let href = V2EXURL + url
        return Alamofire.request(href,parameters: parameters, headers: MOBILE_CLIENT_HEADERS)
    }
    init() {
        MOBILE_CLIENT_HEADERS["user-agent"] = USER_AGENT
    }
    enum ErrorCode: Int {
        case noData = 1
        case dataSerializationFailed = 2
    }
    internal static func newError(_ code: ErrorCode, failureReason: String) -> NSError {
        let errorDomain = "me.fin.v2ex.error"
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        let returnError = NSError(domain: errorDomain, code: code.rawValue, userInfo: userInfo)
        return returnError
    }
    static func JIHTMLResponseSerializer() -> DataResponseSerializer<Ji> {
        return DataResponseSerializer { request, response, data, error in
            guard error == nil else { return .failure(error!) }
            guard let validData = data else {
                return .failure(AFError.responseSerializationFailed(reason: .inputDataNil))
            }
            if  let jiHtml = Ji(htmlData: validData){
                return .success(jiHtml)
            }
            let failureReason = "ObjectMapper failed to serialize response."
            let error = newError(.dataSerializationFailed, failureReason: failureReason)
            return .failure(error)
        }
    }
}
class TopicListModelHTTP {
    typealias V2ValueResponseTopicListModel = (V2ValueResponse<[TopicListModel]>) -> Void
    class func getTopicList(_ tab: String? = nil ,page:Int = 0 ,done: @escaping V2ValueResponseTopicListModel)->Void{
        var params:[String:String] = [:]
        if let tab = tab {
            params["tab"]=tab
        }
        else {
            params["tab"] = "all"
        }
        var url = ""
        if params["tab"] == "all" && page > 0 {
            params.removeAll()
            params["p"] = "\(page)"
            url = "recent"
        }
        let xpath = "//body/div[@id='Wrapper']/div[@class='content']/div[@class='box']/div[@class='cell item']"
        TJHttp().responseNode(url,params,xpath) {JiHtml,jiRootNode, aRootNode ,isSuccess -> Void in
            var resultArray : [TopicListModel] = []
            if aRootNode != nil {
                for aNode in aRootNode! {
                    let topic = TopicListModel(rootNode:aNode)
                    resultArray.append(topic);
                }
                User.shared.getNotificationsCount(jiRootNode!)
            }
            let t = V2ValueResponse<[TopicListModel]>(value:resultArray, success: isSuccess)
            done(t)
        }
    }
    typealias ResponseTopicList =  (V2ValueResponse<([TopicListModel] ,String?)>) -> Void
    class func getTopicList(_ nodeName: String,page:Int,done: @escaping ResponseTopicList){
        let url =  "go/\(nodeName)?p=\(page)"
        let xpath = "//*[@id='Wrapper']/div[@class='content']/div[@class='box']/div[@class='cell']"
        TJHttp().responseNode(url,nil,xpath) {jiHtml,jiRootNode, aRootNode ,isSuccess -> Void in
            var resultArray:[TopicListModel] = []
            var favoriteUrl :String?
            for aNode in aRootNode! {
                let topic = TopicListModel(nodeRootNode: aNode)
                resultArray.append(topic);
            }
            User.shared.getNotificationsCount(jiRootNode!)
            if let node = jiHtml.xPath("//*[@id='Wrapper']/div/div[1]/div[1]/div[1]/a")?.first{
                favoriteUrl = node["href"]
            }
            let t = V2ValueResponse<([TopicListModel], String?)>(value:(resultArray,favoriteUrl), success: isSuccess)
            done(t);
        }
    }
    typealias V2ValueResponseTopicListModelInt = (V2ValueResponse<([TopicListModel],Int)>) -> Void
    class func getFavoriteList(_ page:Int = 1, done: @escaping V2ValueResponseTopicListModelInt){
        let xpath = "//*[@class='cell item']"
        TJHttp().responseNode("my/topics?p=\(page)",nil,xpath){jiHtml,jiRootNode, aRootNode ,isSuccess -> Void in
//        TJHttp().responseJi("my/topics?p=\(page)"){ (response) -> Void in
            var resultArray:[TopicListModel] = []
            var maxPage = 1
                for aNode in aRootNode! {
                    let topic = TopicListModel(favoritesRootNode:aNode)
                    resultArray.append(topic);
                }
                //更新通知数量
                User.shared.getNotificationsCount(jiHtml.rootNode!)
                //获取最大页码 只有第一页需要获取maxPage
                if page <= 1
                    ,let aRootNode = jiHtml.xPath("//*[@class='page_normal']")?.last
                    , let page = aRootNode.content
                    , let pageInt = Int(page)
                {
                    maxPage = pageInt
                }
                let t = V2ValueResponse<([TopicListModel],Int)>(value:(resultArray,maxPage), success: isSuccess)
                done(t);
        }
    }
    class func favorite(_ nodeId:String,type:NSInteger){
        User.shared.getOnce { (response) in
            if(response.success){
                let action = type == 1 ? "favorite/node/" : "unfavorite/node/"
                let url = action + nodeId + "?once=" + User.shared.once!
                TJHttp().responseJi(url) { (response) in
                }
            }
        }
    }
}
