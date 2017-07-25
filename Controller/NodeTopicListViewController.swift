import UIKit
class NodeTopicListViewController: UIViewController   {
    fileprivate weak var _loadView:V2LoadingView?
    func showLoadingView (){
        self._loadView = V2LoadingView(view)
    }
    
    func hideLoadingView() {
        self._loadView?.hideLoadingView()
    }
    var node:NodeModel?
    var favorited:Bool = false
    var favoriteUrl:String? {
        didSet{
//            print(favoriteUrl)
//            let startIndex = favoriteUrl?.range(of: "/", options: .backwards, range: nil, locale: nil)
//            let endIndex = favoriteUrl?.range(of: "?")
//            let nodeId = favoriteUrl?.substring(with: Range<String.Index>( startIndex!.upperBound ..< endIndex!.lowerBound ))
//            if let _ = nodeId , let favoriteUrl = favoriteUrl {
//                favorited =  !favoriteUrl.hasPrefix("/favorite")
//                followButton.refreshButtonImage()
//            }
            favorited =  isFavorite(favoriteUrl)
            followButton.refreshButtonImage()
        }
    }
    func isFavorite(_ favoriteUrl:String?) -> Bool{
        let startIndex = favoriteUrl?.range(of: "/", options: .backwards, range: nil, locale: nil)
        let endIndex = favoriteUrl?.range(of: "?")
        let nodeId = favoriteUrl?.substring(with: Range<String.Index>( startIndex!.upperBound ..< endIndex!.lowerBound ))
        if let _ = nodeId , let favoriteUrl = favoriteUrl {
            return   !favoriteUrl.hasPrefix("/favorite")
        }
        return false
    }
    var followButton:FollowButton!
    fileprivate var _tableView :NodeTable!
    fileprivate var tableView: NodeTable {
        get{
            if(_tableView != nil){
                return _tableView!;
            }
            _tableView = NodeTable();
            return _tableView!
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.node?.nodeId == nil {
            return;
        }
        followButton  = FollowButton(frame:CGRect(x: 0, y: 0, width: 26, height: 26))
        followButton.nodeId = node?.nodeId
        let followItem = UIBarButtonItem(customView: followButton)
        
        //处理间距
        let fixedSpaceItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixedSpaceItem.width = -5
        self.navigationItem.rightBarButtonItems = [fixedSpaceItem,followItem]
        

        self.title = self.node?.nodeName
        self.view.backgroundColor = V2EXColor.colors.v2_backgroundColor
        self.view.addSubview(self.tableView);
        self.tableView.snp.makeConstraints{ (make) -> Void in
            make.top.right.bottom.left.equalTo(self.view);
        }
        self.showLoadingView()
        self.tableView.scrollUp = refresh
        self.tableView.scrollDown = getNextPage
        self.tableView.beginScrollUp()
    }
    var currentPage = 1
    func refresh(_ cb : @escaping Callback){
        TopicListModel.getTopicList(self.node!.nodeId!, page: 1){
            [weak self](response:V2ValueResponse<([TopicListModel],String?)>) -> Void in
            if response.success {
                self?._tableView.topicList = response.value?.0
                self?.favoriteUrl = response.value?.1
                self?.tableView.reloadData()
            }
            self?.hideLoadingView()
            cb()
        }
    }
    func getNextPage(_ cb : @escaping CallbackMore){
        if let count = self.tableView.topicList?.count, count <= 0{
            self.tableView.mj_footer.endRefreshing()
            return;
        }
        self.currentPage += 1
        TopicListModel.getTopicList(self.node!.nodeId!, page: self.currentPage){
            [weak self](response:V2ValueResponse<([TopicListModel],String?)>) -> Void in
            if response.success {
                if let weakSelf = self , let value = response.value  {
                    weakSelf.tableView.topicList! += value.0
                    weakSelf.tableView.reloadData()
                }
                else{
                    self?.currentPage -= 1
                }
            }
            cb(true)
        }
    }
}
fileprivate class NodeTable  : TableBase{
    fileprivate var topicList:Array<TopicListModel>?
    var currentPage = 1
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        backgroundColor = V2EXColor.colors.v2_backgroundColor
        separatorStyle = .none
        regClass(self, cell: HomeTopicListTableViewCell.self)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override fileprivate func rowCount(_ section: Int) -> Int {
        if let list = self.topicList {
            return list.count;
        }
        return 0;
    }
    override fileprivate func rowHeight(_ indexPath: IndexPath) -> CGFloat {
        let item = self.topicList![indexPath.row]
        let titleHeight = item.getHeight() ?? 0
        //          上间隔   头像高度  头像下间隔       标题高度    标题下间隔 cell间隔
        let height = 12    +  35     +  12      + titleHeight   + 12      + 8
        return height

    }
    override fileprivate func cellAt(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = getCell(self, cell: HomeTopicListTableViewCell.self, indexPath: indexPath);
        cell.bindNodeModel(self.topicList![indexPath.row]);
        return cell;
    }
    override fileprivate func didSelectRowAt(_ indexPath: IndexPath) {
        let item = self.topicList![indexPath.row]
        if let id = item.topicId {
            Msg.send("openTopicDetail1", [id])
            self.deselectRow(at: indexPath, animated: true)
        }
    }
}
class FollowButton : ButtonBase{
    override init(frame: CGRect) {
        super.init(frame: frame)
        tap = toggleFavoriteState
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var favorited:Bool = false
    var nodeId:String?
    func refreshButtonImage() {
        let followImage = self.favorited == true ? UIImage(named: "ic_favorite")! : UIImage(named: "ic_favorite_border")!
        self.setImage(followImage.withRenderingMode(.alwaysTemplate), for: UIControlState())
    }
    func toggleFavoriteState(){
        if(self.favorited){
            TopicListModel.favorite(self.nodeId!, type: 0)
            self.favorited = false
            V2Success("取消收藏了~")
        }
        else{
            TopicListModel.favorite(self.nodeId!, type: 1)
            self.favorited = true
            V2Success("收藏成功")
        }
        refreshButtonImage()
    }

}
