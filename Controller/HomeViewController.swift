import UIKit
import Kingfisher
import YYText
import SnapKit
import Alamofire
import AlamofireObjectMapper
import Ji
import MJRefresh
import Cartography

class HomeViewController: TJPage {
    var tab:String? = nil
    var currentPage = 0
    fileprivate var tableView: TableHome {
        get{
            return TableHome.shared
        }
    }
    override func onShow(){
        Msg.send("PanningGestureEnable")
    }
    override func onHide(){
        Msg.send("PanningGestureDisable")
    }
    override func onLoad() {
        self.navigationItem.title="V2EX";
        self.tab = Setting.shared.kHomeTab
        refreshPage()
    }
    var timer = SecondTimer(120)
    override func onAppRise() {
        if timer.isArrived {
            self.tableView.beginScrollUp()
        }
    }
    override func onAppFall(){
        timer.begin()
    }
    func refreshPage(){
        Setting.shared.kHomeTab = tab
//        self.tableView.beginScrollUp()
        refresh(){
            
        }
    }
    override func onLayout() {
        constrain(view, tableView){
            $1.left   == $0.left
            $1.right  == $0.right
            $1.bottom == $0.bottom
            $1.top    == $0.top
        }
    }
    override func getSubviews()->[UIView]?{
        tableView.scrollUp = refresh
        tableView.scrollDown = getNextPage
        self.tableView.backgroundColor = V2EXColor.colors.v2_backgroundColor
        return [tableView]
    }
    override func getNavItems ()->[UIButton]{
        return [NotificationMenuButton(), RightButton()]
    }
    func refresh(_ cb : @escaping  Callback){
        TopicListModelHTTP.getTopicList(tab){response in
            if response.success {
                self.tableView.topicList = response.value
                self.tableView.reloadData()
                self.currentPage = 0
            }
            cb()
        }
    }
    func getNextPage(_ cb : @escaping CallbackMore){
        if let count = self.tableView.topicList?.count , count <= 0{
            self.tableView.mj_footer.endRefreshing()
            return;
        }
        self.currentPage += 1
        print(currentPage)
        TopicListModelHTTP.getTopicList(tab,page:currentPage){response in
            if response.success {
                self.tableView.topicList! += response.value!
                self.tableView.reloadData()
            }
            cb(true)
            if response.value?.count == 0 {
                self.currentPage -= 1
            }
        }
    }
}
class HomeData : TJTableDataSource{
    var topicList:[TopicListModel]?
    override func sectionCount() -> Int {
        return 1
    }
    override func rowCount(_ section: Int) -> Int {
        if let list = self.topicList {
            return list.count;
        }
        return 0;
    }
    override func rowHeight(_ indexPath: IndexPath) -> CGFloat {
        let item = self.topicList![indexPath.row]
        let titleHeight = item.getHeight() ?? 0
        let height = fixHeight ()  + titleHeight
        return height
    }
    override func cellTypes() ->[UITableViewCell.Type]{
        return [HomeTopicListTableViewCell.self]
    }
    func fixHeight()-> CGFloat{
        let height = 12    +  35     +  12    +  12      + 8
        return CGFloat(height)
        //          上间隔   头像高度  头像下间隔     标题下间隔 cell间隔
    }
    override func getDataItem(_ indexPath : IndexPath) -> TableDataSourceItem{
        return topicList![indexPath.row].toDict()
    }
}
fileprivate class  TableHome : TJTable {
    static fileprivate var _tableView :TableHome!
    fileprivate class var shared: TableHome {
        get{
            if(_tableView != nil){
                return _tableView!;
            }
            _tableView = TableHome();
            return _tableView!;
        }
    }
    var topicList:[TopicListModel]?{
        get{
            return homedata?.topicList
        }
        set{
            homedata?.topicList = newValue
        }
    }
    var homedata :  HomeData?
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame:frame,style:style)
        separatorStyle = UITableViewCellSeparatorStyle.none;
        homedata =  HomeData()
        tableData = homedata
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    override func didSelectRowAt(_ indexPath: IndexPath) {
        let item = self.topicList![indexPath.row]
        if let id = item.topicId {
            let a = {[weak self] (topicId : String)->Void in
                self?.perform(#selector(self?.ignoreTopicHandler(_:)), with: topicId, afterDelay: 0.6)
            }
            Msg.send("openTopicDetail",[id,a])
            deselectRow(at: indexPath, animated: true);
        }
    }
    // 当用户点击忽略按钮（在TopicDetailController内），执行它
    func ignoreTopicHandler(_ topicId:String) {
        let index = self.topicList?.index(where: {$0.topicId == topicId })
        if index == nil {
            return
        }
        //看当前忽略的cell 是否在可视列表里
        let indexPaths = indexPathsForVisibleRows
        let visibleIndex =  indexPaths?.index(where: {($0 as IndexPath).row == index})
        self.topicList?.remove(at: index!)
        //如果不在可视列表，则直接reloadData 就可以
        if visibleIndex == nil {
            reloadData()
            return
        }
        //如果在可视列表，则动画删除它
        beginUpdates()
        deleteRows(at: [IndexPath(row: index!, section: 0)], with: .fade)
        endUpdates()
    }
}
fileprivate class RightButton : TJButton{
    override func onLoad() {
        frame = TJSquare(0,0,40)
        contentMode = .center
        imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -15)
        icon = "ic_more_horiz_36pt"
        tap = rightClick
    }
    func rightClick(){
        Msg.send("openRightDrawer")
    }
}
//fileprivate class NotificationMenuButton: UIButton {
fileprivate class NotificationMenuButton: TJButton {
    var aPointImageView:UIImageView?
     override func onLoad() {
        let rect = TJSquare(0,0,40)
        self.frame = rect
        self.contentMode = .center
        self.imageEdgeInsets = UIEdgeInsetsMake(0, -15, 0, 0)
        self.setImage(UIImage.imageUsedTemplateMode("ic_menu_36pt")!, for: .normal)
        self.aPointImageView = UIImageView()
        self.aPointImageView!.backgroundColor = V2EXColor.colors.v2_NoticePointColor
        self.aPointImageView!.layer.cornerRadius = 4
        self.aPointImageView!.layer.masksToBounds = true
        self.addSubview(self.aPointImageView!)
        self.aPointImageView!.snp.makeConstraints{ (make) -> Void in
            make.width.height.equalTo(8)
            make.top.equalTo(self).offset(3)
            make.right.equalTo(self).offset(-6)
        }
        tap = leftClick
        self.kvoController.observe(User.shared, keyPath: "notificationCount", options: [.initial,.new]) {  [weak self](cell, clien, change) -> Void in
            if User.shared.notificationCount > 0 {
                self?.aPointImageView!.isHidden = false
            }
            else{
                self?.aPointImageView!.isHidden = true
            }
        }
    }
    func leftClick(){
        Msg.send("openLeftDrawer")
    }
}
class HomeTopicListTableViewCell: TJCell {
    var model : TopicListModel?
    override func load(_ data : PCTableDataSource,_ item : TableDataSourceItem,_ indexPath : IndexPath){
        let model = TopicListModel()
        model.fromDict(item)
        self.bind(model)
    }
    /// class
    class ReplyIcon : UIImageView{
        init() {
            super.init(image: UIImage(named: "reply_n"))
            contentMode = .scaleAspectFit
        }
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    // property
    var _avatar =  Avatar()
    var _user = SizeLabel(14)
    var _date = SizeLabel(12)
    var _reply = SizeLabel(12)
    var _replyIcon = ReplyIcon()
    var _node = SizeLabel(11)
    var _nodeback  = UIImageView()
    var _title = LinesLabel(18)
    var _panel:UIView = UIView()
    var itemModel:TopicListModel?
    var Labels : [String:UILabel]?
    override func setup()->Void{
        self.contentView .addSubview(self._panel);
        self._panel.addSubview(self._avatar);
        self._panel.addSubview(self._user);
        self._panel.addSubview(self._date);
        self._panel.addSubview(self._reply);
        self._panel.addSubview(self._replyIcon);
        self._panel.addSubview(self._nodeback)
        self._panel.addSubview(self._node)
        self._panel.addSubview(self._title);
        self.setupLayout()
        self.backgroundColor = V2EXColor.colors.v2_backgroundColor
        self._panel.backgroundColor = V2EXColor.colors.v2_CellWhiteBackgroundColor
        self._avatar.tap = userNameTap
        self._user.tap = userNameTap
    }
    func userNameTap() {
        if let _ = self.itemModel , let username = itemModel?.userName {
            Msg.send("pushMemberViewController",[username])
        }
    }
    fileprivate func setupLayout(){
        constrain(_panel,_avatar,_user,_date,_reply)
        {content,avatar,userName ,date,replyCount in
            content.top == content.superview!.top
            content.left == content.superview!.left
            content.right == content.superview!.right
            content.bottom == (content.superview?.bottom)! - 8
            // to content
            avatar.left == content.left + 12
            avatar.top == content.top + 12
            avatar.width == 35
            avatar.height == 35
            //
            userName.left == avatar.right + 10
            userName.top  == avatar.top
            //
            date.bottom == avatar.bottom
            date.left   == userName.left
        }
        constrain(_panel,_avatar,_reply,_replyIcon,_node){
            content,avatar,replyCount,replyIcon ,nodeName in
            //
            replyCount.top == avatar.top
            replyCount.right   == content.right - 12
            //
            replyIcon.top == avatar.top
            replyIcon.right == replyCount.left - 2
            //
            nodeName.top == avatar.top
            nodeName.right   == replyIcon.left - 9
        }
        constrain(_node,_nodeback){nodeName,nodeback in
            nodeback.top    == nodeName.top
            nodeback.bottom == nodeName.bottom
            nodeback.right  == nodeName.right + 5
            nodeback.left   == nodeName.left - 5
        }
        constrain(_panel,_avatar,_title){
            content,avatar,title in
            title.top == avatar.bottom + 12
            title.left == avatar.left
            title.right == content.right - 12
            title.bottom == content.bottom - 8
        }
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    func superBind(_ model:TopicListModel){
        self._user.text = model.userName;
        if let layout = model.topicTitle {
            // avoid flash
            if layout  == self.itemModel?.topicTitle {
                return
            }
            else{
                self._title.text =  model.topicTitle
            }
        }
        if let avata = model.avata {
            self._avatar.fin_setImageWithUrl(URL(string: "https:" + avata)!, placeholderImage: nil, imageModificationClosure: fin_defaultImageModification() )
        }
        self._reply.text = model.replies;
        self.itemModel = model
    }
    func bind(_ model:TopicListModel){
        self.superBind(model)
        self._date.text = model.date
        self._node.text = model.nodeName
    }
    func bindNodeModel(_ model:TopicListModel){
        self.superBind(model)
        self._date.text = model.hits
        self._nodeback.isHidden = true
    }
}
