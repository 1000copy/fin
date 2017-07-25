import UIKit
import Kingfisher
import YYText
import SnapKit
import Alamofire
import AlamofireObjectMapper
import Ji
import MJRefresh
import Cartography
let kHomeTab = "me.fin.homeTab"
class HomeViewController: UIViewController {
    var tab:String? = nil
    var currentPage = 0
    fileprivate var tableView: TableHome {
        get{
            return TableHome.shared
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        Msg.send("PanningGestureEnable")
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        Msg.send("PanningGestureDisable")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title="V2EX";
        self.tab = Setting.shared.kHomeTab
        self.setupNavigationItem()
        
        //监听程序即将进入前台运行、进入后台休眠 事件
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        self.view.addSubview(self.tableView);
        self.tableView.snp.makeConstraints{ (make) -> Void in
            make.top.right.bottom.left.equalTo(self.view);
        }
        tableView.scrollUp = refresh
        tableView.scrollDown = getNextPage
        refreshPage()
        self.thmemChangedHandler = {[weak self] (style) -> Void in
            self?.tableView.backgroundColor = V2EXColor.colors.v2_backgroundColor
        }
    }
    func refreshPage(){
        Setting.shared.kHomeTab = tab
        self.tableView.beginScrollUp()
    }
    func setupNavigationItem(){
        let leftButton = NotificationMenuButton()
        leftButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftButton)
        leftButton.addTarget(self, action: #selector(leftClick), for: .touchUpInside)
        
        
        let rightButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        rightButton.contentMode = .center
        rightButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -15)
        rightButton.setImage(UIImage.imageUsedTemplateMode("ic_more_horiz_36pt")!.withRenderingMode(.alwaysTemplate), for: UIControlState())
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
        rightButton.addTarget(self, action: #selector(rightClick), for: .touchUpInside)

    }
    func leftClick(){
        Msg.send("openLeftDrawer")
    }
    func rightClick(){
        Msg.send("openRightDrawer")
    }
    func refresh(_ cb : @escaping  Callback){
        TopicListModel.get(tab){
            self.tableView.topicList = $0
            self.tableView.reloadData()
            self.currentPage = 0
            cb()
        }
    }
    func getNextPage(_ cb : @escaping CallbackMore){
        if let count = self.tableView.topicList?.count , count <= 0{
            self.tableView.mj_footer.endRefreshing()
            return;
        }
        self.currentPage += 1
        TopicListModel.get(tab,self.currentPage){
            self.tableView.topicList = $0
            self.tableView.reloadData()
            self.currentPage = 0
            cb(true)
            if $0?.count == 0 {
                self.currentPage -= 1
            }
        }
    }
    
    static var lastLeaveTime = Date()
    func applicationWillEnterForeground(){
        //计算上次离开的时间与当前时间差
        //如果超过2分钟，则自动刷新本页面。
        let interval = -1 * HomeViewController.lastLeaveTime.timeIntervalSinceNow
        if interval > 120 {
            self.tableView.mj_header.beginRefreshing()
        }
    }
    func applicationDidEnterBackground(){
        HomeViewController.lastLeaveTime = Date()
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
fileprivate class NotificationMenuButton: UIButton {
    var aPointImageView:UIImageView?
    required init(){
        super.init(frame: CGRect.zero)
        self.contentMode = .center
        self.imageEdgeInsets = UIEdgeInsetsMake(0, -15, 0, 0)
        self.setImage(UIImage.imageUsedTemplateMode("ic_menu_36pt")!, for: UIControlState())
        
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
        
        self.kvoController.observe(User.shared, keyPath: "notificationCount", options: [.initial,.new]) {  [weak self](cell, clien, change) -> Void in
            if User.shared.notificationCount > 0 {
                self?.aPointImageView!.isHidden = false
                
            }
            else{
                self?.aPointImageView!.isHidden = true
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
class HomeTopicListTableViewCell: TJCell {
    override func load(_ data : PCTableDataSource,_ item : TableDataSourceItem,_ indexPath : IndexPath){
        let model = TopicListModel()
        model.fromDict(item)
        self.bind(model)
    }
    //? 为什么用这个圆角图片，而不用layer.cornerRadius
    // 因为 设置 layer.cornerRadius 太耗系统资源，每次滑动 都需要渲染很多次，所以滑动掉帧
    // iOS中可以缓存渲染，但效果还是不如直接 用圆角图片
    
    /// 节点信息label的圆角背景图
    fileprivate static var nodeBackgroundImage_Default =
        createImageWithColor( V2EXDefaultColor.sharedInstance.v2_NodeBackgroundColor ,size: CGSize(width: 10, height: 20))
            .roundedCornerImageWithCornerRadius(2)
            .stretchableImage(withLeftCapWidth: 3, topCapHeight: 3)
    fileprivate static var nodeBackgroundImage_Dark =
        createImageWithColor( V2EXDarkColor.sharedInstance.v2_NodeBackgroundColor ,size: CGSize(width: 10, height: 20))
            .roundedCornerImageWithCornerRadius(2)
            .stretchableImage(withLeftCapWidth: 3, topCapHeight: 3)
    
    /// class
    class Avatar : UIImageView{
        override func layoutSubviews() {
            contentMode = .scaleAspectFit
            frame.size.height = 35
            frame.size.width = 35
        }
    }
    class SizeLabel : UILabel{
        init(_ fontSize : CGFloat){
            super.init(frame: CGRect.zero)
            font = v2Font(fontSize)
        }
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
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
    var avatarImageView =  Avatar()
    /// 用户名
    var userNameLabel = SizeLabel(14)
    var dateAndLastPostUserLabel = SizeLabel(12)
    var replyCountLabel = SizeLabel(12)
    var replyCountIconImageView = ReplyIcon()
    /// 节点
    var nodeNameLabel = SizeLabel(11)
    var nodeBackgroundImageView  = UIImageView()
    /// 帖子标题
//    var topicTitleLabel: YYLabel = {
//        let label = YYLabel()
//        label.textVerticalAlignment = .top
//        label.font=v2Font(18)
//        label.displaysAsynchronously = true
//        label.numberOfLines=0
//        return label
//    }()
    var topicTitleLabel = SizeLabel(18)
    /// 装上面定义的那些元素的容器
    var contentPanel:UIView = UIView()
    
    var itemModel:TopicListModel?
    override func setup()->Void{
        let selectedBackgroundView = UIView()
        self.selectedBackgroundView = selectedBackgroundView
        
        self.contentView .addSubview(self.contentPanel);
        self.contentPanel.addSubview(self.avatarImageView);
        self.contentPanel.addSubview(self.userNameLabel);
        self.contentPanel.addSubview(self.dateAndLastPostUserLabel);
        self.contentPanel.addSubview(self.replyCountLabel);
        self.contentPanel.addSubview(self.replyCountIconImageView);
        self.contentPanel.addSubview(self.nodeBackgroundImageView)
        self.contentPanel.addSubview(self.nodeNameLabel)
        self.contentPanel.addSubview(self.topicTitleLabel);
        
        self.setupLayout()
        
        self.thmemChangedHandler = {[weak self] (style) -> Void in
            if style == V2EXColor.V2EXColorStyleDefault {
                self?.nodeBackgroundImageView.image = HomeTopicListTableViewCell.nodeBackgroundImage_Default
            }
            else{
                self?.nodeBackgroundImageView.image = HomeTopicListTableViewCell.nodeBackgroundImage_Dark
            }
            
            self?.backgroundColor=V2EXColor.colors.v2_backgroundColor;
            self?.selectedBackgroundView!.backgroundColor = V2EXColor.colors.v2_backgroundColor
            self?.contentPanel.backgroundColor = V2EXColor.colors.v2_CellWhiteBackgroundColor
            self?.userNameLabel.textColor = V2EXColor.colors.v2_TopicListUserNameColor;
            self?.dateAndLastPostUserLabel.textColor=V2EXColor.colors.v2_TopicListDateColor;
            self?.replyCountLabel.textColor = V2EXColor.colors.v2_TopicListDateColor
            self?.nodeNameLabel.textColor = V2EXColor.colors.v2_TopicListDateColor
            self?.topicTitleLabel.textColor=V2EXColor.colors.v2_TopicListTitleColor;
            
            self?.avatarImageView.backgroundColor = self?.contentPanel.backgroundColor
            self?.userNameLabel.backgroundColor = self?.contentPanel.backgroundColor
            self?.dateAndLastPostUserLabel.backgroundColor = self?.contentPanel.backgroundColor
            self?.replyCountLabel.backgroundColor = self?.contentPanel.backgroundColor
            self?.replyCountIconImageView.backgroundColor = self?.contentPanel.backgroundColor
            self?.topicTitleLabel.backgroundColor = self?.contentPanel.backgroundColor
        }
        
        //点击用户头像，跳转到用户主页
        self.avatarImageView.isUserInteractionEnabled = true
        self.userNameLabel.isUserInteractionEnabled = true
        var userNameTap = UITapGestureRecognizer(target: self, action: #selector(HomeTopicListTableViewCell.userNameTap(_:)))
        self.avatarImageView.addGestureRecognizer(userNameTap)
        userNameTap = UITapGestureRecognizer(target: self, action: #selector(HomeTopicListTableViewCell.userNameTap(_:)))
        self.userNameLabel.addGestureRecognizer(userNameTap)
        
    }
    
    fileprivate func setupLayout(){
        constrain(contentPanel,avatarImageView,userNameLabel,dateAndLastPostUserLabel,replyCountLabel)
        {content,avatar,userName ,date,replyCount in
            content.top == content.superview!.top
            content.left == content.superview!.left
            content.right == content.superview!.right
            content.bottom == (content.superview?.bottom)! - 8
            // to content
            avatar.left == content.left + 12
            avatar.top == content.top + 12
            //
            userName.left == avatar.right + 10
            userName.top  == avatar.top
            //
            date.bottom == avatar.bottom
            date.left   == userName.left
        }
        constrain(contentPanel,avatarImageView,replyCountLabel,replyCountIconImageView,nodeNameLabel){
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
        constrain(nodeNameLabel,nodeBackgroundImageView){nodeName,nodeback in
            nodeback.top    == nodeName.top
            nodeback.bottom == nodeName.bottom
            nodeback.right  == nodeName.right + 5
            nodeback.left   == nodeName.left - 5
            
        }
        constrain(contentPanel,avatarImageView,topicTitleLabel){
            content,avatar,title in
            title.top == avatar.bottom + 12
            title.left == avatar.left
            title.right == content.right - 12
            title.bottom == content.bottom - 8
        }
//        self.contentPanel.snp.makeConstraints{ (make) -> Void in
//            make.top.left.right.equalTo(self.contentView);
//        }
//        self.avatarImageView.snp.makeConstraints{ (make) -> Void in
//            make.left.top.equalTo(self.contentView).offset(12)
//            make.width.height.equalTo(35)
//        }
//        self.userNameLabel.snp.makeConstraints{ (make) -> Void in
//            make.left.equalTo(self.avatarImageView.snp.right).offset(10)
//            make.top.equalTo(self.avatarImageView)
//        }
//        self.dateAndLastPostUserLabel.snp.makeConstraints{ (make) -> Void in
//            make.bottom.equalTo(self.avatarImageView)
//            make.left.equalTo(self.userNameLabel)
//        }
//        self.replyCountLabel.snp.makeConstraints{ (make) -> Void in
//            make.centerY.equalTo(self.userNameLabel);
//            make.right.equalTo(self.contentPanel).offset(-12)
//        }
//        self.replyCountIconImageView.snp.makeConstraints{ (make) -> Void in
//            make.centerY.equalTo(self.replyCountLabel);
//            make.width.height.equalTo(18);
//            make.right.equalTo(self.replyCountLabel.snp.left).offset(-2);
//        }
//        self.nodeNameLabel.snp.makeConstraints{ (make) -> Void in
//            make.centerY.equalTo(self.replyCountLabel);
//            make.right.equalTo(self.replyCountIconImageView.snp.left).offset(-9)
//            make.bottom.equalTo(self.replyCountLabel).offset(1);
//            make.top.equalTo(self.replyCountLabel).offset(-1);
//        }
//        self.nodeBackgroundImageView.snp.makeConstraints{ (make) -> Void in
//            make.top.bottom.equalTo(self.nodeNameLabel)
//            make.left.equalTo(self.nodeNameLabel).offset(-5)
//            make.right.equalTo(self.nodeNameLabel).offset(5)
//        }
//        self.topicTitleLabel.snp.makeConstraints{ (make) -> Void in
//            make.top.equalTo(self.avatarImageView.snp.bottom).offset(12);
//            make.left.equalTo(self.avatarImageView);
//            make.right.equalTo(self.contentPanel).offset(-12);
//            make.bottom.equalTo(self.contentView).offset(-8)
//        }
//        self.contentPanel.snp.makeConstraints{ (make) -> Void in
//            make.bottom.equalTo(self.contentView.snp.bottom).offset(-8);
//        }
    }
    
//    fileprivate func setupLayout(){
//        layout(contentView,
//               ["panel":contentPanel],
//               ["H:|-0-[panel]-0-|","V:|-0-[panel]-0-|"],
//               [.None,.None])
////        self.contentPanel.snp.makeConstraints{ (make) -> Void in
////            make.top.left.right.equalTo(self.contentView);
////        }
//        layout(contentView,
//               ["avatar":avatarImageView],
//               ["H:|-12-[avatar(35)]","V:|-12-[avatar(35)]"],
//               [.None,.None])
////        self.avatarImageView.snp.makeConstraints{ (make) -> Void in
////            make.left.top.equalTo(self.contentView).offset(12);
////            make.width.height.equalTo(35);
////        }
//        layout(contentView,
//               ["avatar":avatarImageView,"username":userNameLabel],
//               ["H:[avatar]-10-[username]","V:|-12-[username]"],
//               [.None,.None])
////        self.userNameLabel.snp.makeConstraints{ (make) -> Void in
////            make.left.equalTo(self.avatarImageView.snp.right).offset(10);
////            make.top.equalTo(self.avatarImageView);
////        }
////        layout(contentView,
////               ["avatar":avatarImageView,"dateand":dateAndLastPostUserLabel],
////               ["H:[avatar]-10-[username]","V:|-12-[username]"],
////               [.None,.None])
//        self.dateAndLastPostUserLabel.snp.makeConstraints{ (make) -> Void in
//            make.bottom.equalTo(self.avatarImageView);
//            make.left.equalTo(self.userNameLabel);
//        }
//        self.replyCountLabel.snp.makeConstraints{ (make) -> Void in
//            make.centerY.equalTo(self.userNameLabel);
//            make.right.equalTo(self.contentPanel).offset(-12);
//        }
//        self.replyCountIconImageView.snp.makeConstraints{ (make) -> Void in
//            make.centerY.equalTo(self.replyCountLabel);
//            make.width.height.equalTo(18);
//            make.right.equalTo(self.replyCountLabel.snp.left).offset(-2);
//        }
//        self.nodeNameLabel.snp.makeConstraints{ (make) -> Void in
//            make.centerY.equalTo(self.replyCountLabel);
//            make.right.equalTo(self.replyCountIconImageView.snp.left).offset(-9)
//            make.bottom.equalTo(self.replyCountLabel).offset(1);
//            make.top.equalTo(self.replyCountLabel).offset(-1);
//        }
//        self.nodeBackgroundImageView.snp.makeConstraints{ (make) -> Void in
//            make.top.bottom.equalTo(self.nodeNameLabel)
//            make.left.equalTo(self.nodeNameLabel).offset(-5)
//            make.right.equalTo(self.nodeNameLabel).offset(5)
//        }
//        self.topicTitleLabel.snp.makeConstraints{ (make) -> Void in
//            make.top.equalTo(self.avatarImageView.snp.bottom).offset(12);
//            make.left.equalTo(self.avatarImageView);
//            make.right.equalTo(self.contentPanel).offset(-12);
//            make.bottom.equalTo(self.contentView).offset(-8)
//        }
//        self.contentPanel.snp.makeConstraints{ (make) -> Void in
//            make.bottom.equalTo(self.contentView.snp.bottom).offset(-8);
//        }
//    }
    
    func userNameTap(_ sender:UITapGestureRecognizer) {
        if let _ = self.itemModel , let username = itemModel?.userName {
            Msg.send("pushMemberViewController",[username])
        }
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func superBind(_ model:TopicListModel){
        self.userNameLabel.text = model.userName;
        if let layout = model.topicTitle {
            // avoid flash
            if layout  == self.itemModel?.topicTitle {
                return
            }
            else{
                self.topicTitleLabel.text =  model.topicTitle
                topicTitleLabel.numberOfLines = 0
                topicTitleLabel.lineBreakMode = .byWordWrapping
            }
        }
        if let avata = model.avata {
            self.avatarImageView.fin_setImageWithUrl(URL(string: "https:" + avata)!, placeholderImage: nil, imageModificationClosure: fin_defaultImageModification() )
        }
        self.replyCountLabel.text = model.replies;
        
        self.itemModel = model
    }
    
    func bind(_ model:TopicListModel){
        self.superBind(model)
        self.dateAndLastPostUserLabel.text = model.date
        self.nodeNameLabel.text = model.nodeName
    }
    
    func bindNodeModel(_ model:TopicListModel){
        self.superBind(model)
        self.dateAndLastPostUserLabel.text = model.hits
        self.nodeBackgroundImageView.isHidden = true
    }
}
