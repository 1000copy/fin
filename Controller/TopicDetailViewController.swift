import UIKit
class TopicDetailViewController: UIViewController{
    fileprivate weak var _loadView:V2LoadingView?
    func showLoadingView (){
        self._loadView = V2LoadingView(view)
    }
    
    func hideLoadingView() {
        self._loadView?.hideLoadingView()
    }
    var topicId = "0"
    var currentPage = 1
    fileprivate var webViewContentCell:TopicDetailWebViewContentCell?
    fileprivate var _tableView :Table1!
    fileprivate var tableView: Table1 {
        get{
            if(_tableView != nil){
                return _tableView!;
            }
            _tableView = Table1();
            _tableView.viewControler = self
//            _tableView.model = model
//            _tableView.tableView = _tableView
//            _tableView.commentsArray = commentsArray
            _tableView.separatorStyle = UITableViewCellSeparatorStyle.none;
            
            _tableView.backgroundColor = V2EXColor.colors.v2_backgroundColor
//            regClass(_tableView, cell: TopicDetailHeaderCell.self)
//            regClass(_tableView, cell: TopicDetailWebViewContentCell.self)
//            regClass(_tableView, cell: TopicDetailCommentCell.self)
//            regClass(_tableView, cell: BaseDetailTableViewCell.self)
            
            
            return _tableView!;
            
        }
    }
    /// 忽略帖子成功后 ，调用的闭包
    var ignoreTopicHandler : ((String) -> Void)?
    //点击右上角more按钮后，弹出的 activityView
    //只在activityView 显示在屏幕上持有它，如果activityView释放了，这里也一起释放。
    fileprivate weak var activityView:V2ActivityViewController?
    
    //MARK: - 页面事件
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("postDetails")
        self.view.backgroundColor = V2EXColor.colors.v2_backgroundColor
        self.view.addSubview(self.tableView);
        self.tableView.snp.makeConstraints{ (make) -> Void in
            make.top.right.bottom.left.equalTo(self.view);
        }
        
        let rightButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        rightButton.contentMode = .center
        rightButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -15)
        rightButton.setImage(UIImage(named: "ic_more_horiz_36pt")!.withRenderingMode(.alwaysTemplate), for: UIControlState())
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
        rightButton.addTarget(self, action: #selector(TopicDetailViewController.rightClick), for: .touchUpInside)
        self.showLoadingView()
        self.tableView.scrollUp = getData
        self.tableView.scrollDown = getNextPage
        self.tableView.beginScrollUp()
    }
    
    func getData(_ cb : @escaping Callback){
        //根据 topicId 获取 帖子信息 、回复。
        TopicDetailModel.getTopicDetailById(self.topicId){
            (response:V2ValueResponse<(TopicDetailModel?,[TopicCommentModel])>) -> Void in
            if response.success {
                
                if let aModel = response.value!.0{
                    self.tableView.model = aModel
                }
                self._tableView.commentsArray = response.value!.1
                self.currentPage = 1
                //清除将帖子内容cell,因为这是个缓存，如果赋值后，就会cache到这个变量，之后直接读这个变量不重新赋值。
                //这里刷新了，则可能需要更新帖子内容cell ,实际上只是重新调用了 cell.load(_:)方法
                self.webViewContentCell = nil
                self.tableView.reloadData()
            }
            else{
                V2Error("刷新失败");
            }
            self.hideLoadingView()
            cb()
        }
    }
    func rightClick(){
        if  self._tableView.model != nil {
            let activityView = V2ActivityViewController()
            activityView.dataSource = self
            self.navigationController!.present(activityView, animated: true, completion: nil)
            self.activityView = activityView
        }
    }
    func getNextPage(_ cb : @escaping CallbackMore){
        if self._tableView.model == nil || self._tableView.commentsArray.count <= 0 {
            cb(false)
            return;
        }
        self.currentPage += 1
        if self._tableView.model == nil || self.currentPage > self._tableView.model!.commentTotalPages {
            cb(false)
            return;
        }
        TopicDetailModel.getTopicCommentsById(self.topicId, page: self.currentPage) { (response) -> Void in
            if response.success {
                self._tableView.commentsArray += response.value!
                self.tableView.reloadData()
                cb(true)
                if self.currentPage == self._tableView.model?.commentTotalPages {
                    cb(false)
                }
            }
            else{
                self.currentPage -= 1
            }
        }
    }
}
enum TopicDetailTableViewSection: Int {
    case header = 0, comment, other
}

enum TopicDetailHeaderComponent: Int {
    case title = 0,  webViewContent, other
}
class TopicTitleLabel :V2SpacingLabel{
    override init(frame:CGRect) {
        super.init(frame: frame)
        let label = self
        label.textColor = V2EXColor.colors.v2_TopicListTitleColor;
        label.font = v2Font(17);
        label.numberOfLines = 0;
        label.preferredMaxLayoutWidth = SCREEN_WIDTH-24;
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    class func heightFor(_ text : String?) -> CGFloat{
        if let t = text {
            let  lbl = TopicTitleLabel()
            lbl.text = t
            return lbl.sizeThatFits(CGSize(width: SCREEN_WIDTH - 12 - 12 , height: 9999)).height
        }else
        {
            return 0
        }
    }
}

fileprivate class Table1:  TJTable{
    var viewControler : UIViewController?
    var topicId = "0"
    var currentPage = 1
//    var tableView : TableBase?
    fileprivate var model:TopicDetailModel?
    fileprivate var commentsArray:[TopicCommentModel] = []
    fileprivate var webViewContentCell:TopicDetailWebViewContentCell?
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame,style:style)
        registerCells()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func sectionCount() -> Int {
        return 2
    }
    fileprivate override func didSelectRowAt(_ indexPath: IndexPath) {
        let sheet = Sheet()
        sheet.ActionSheet(indexPath, viewControler!, self)
    }
    fileprivate override func cellTypes() -> [UITableViewCell.Type] {
        return [TopicDetailHeaderCell.self,TopicDetailWebViewContentCell.self,
        TopicDetailCommentCell.self,
        BaseDetailTableViewCell.self]
    }
    override func getDataItem(_ indexPath : IndexPath) -> TableDataSourceItem{
        var item = TableDataSourceItem()
        if indexPath.section == 0 && indexPath.row == 0 {
            item = (model?.toDict())!
        }
        if indexPath.section == 0 && indexPath.row == 1 {
            item = (model?.toDict())!
        }
        return item
    }
    override func rowCount(_ section: Int) -> Int {
        let _section = TopicDetailTableViewSection(rawValue: section)!
        switch _section {
        case .header:
            if self.model != nil{
                return 3
            }
            else{
                return 0
            }
        case .comment:
            return self.commentsArray.count;
        case .other:
            return 0;
        }
    }
    override func rowHeight(_ indexPath: IndexPath) -> CGFloat {
        let _section = TopicDetailTableViewSection(rawValue: indexPath.section)!
        var _headerComponent = TopicDetailHeaderComponent.other
        if let headerComponent = TopicDetailHeaderComponent(rawValue: indexPath.row) {
            _headerComponent = headerComponent
        }
        switch _section {
        case .header:
            switch _headerComponent {
            case .title:
                return TopicTitleLabel.heightFor(self.model!.topicTitle) + 12 + 48 + 12
            case .webViewContent:
                if let height =  self.webViewContentCell?.contentHeight , height > 0 {
                    return height
                }
                else {
                    return 1
                }
            case .other:
                return 45
            }
        case .comment:
            let layout = self.commentsArray[indexPath.row].textLayout!
            return layout.textBoundingRect.size.height + 12 + 35 + 12 + 12 + 1
        case .other:
            return 200
        }
    }
    override func cellTypeAt(_ indexPath:IndexPath) -> UITableViewCell.Type{
        if indexPath.section == 0 && indexPath.row == 0 {
            return TopicDetailHeaderCell.self
        }
        if indexPath.section == 0 && indexPath.row == 1 {
            return TopicDetailWebViewContentCell.self
        }
        if indexPath.section == 0 && indexPath.row == 2 {
            return BaseDetailTableViewCell.self
        }
        if indexPath.section == 1 {
            return TopicDetailCommentCell.self
        }
        return UITableViewCell.self
    }
    func webCellheightChanged(height:CGFloat) {
            //在cell显示在屏幕时更新，否则会崩溃会崩溃会崩溃
            //另外刷新清空旧cell,重新创建这个cell ,所以 contentHeightChanged 需要判断cell是否为nil
            if let cell = self.webViewContentCell, self.visibleCells.contains(cell) {
                beginUpdates()
                endUpdates()
            }
    }
    override func cellAt(_ indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 && indexPath.row == 0 {
            let cell = super.cellAt(indexPath) as! TopicDetailHeaderCell
            if(cell.nodeClickHandler == nil){
                cell.nodeClickHandler = {[weak self] () -> Void in
                    self?.nodeClick()
                }
            }
            return cell;
        }
        if indexPath.section == 0 && indexPath.row == 1 {
            self.webViewContentCell = super.cellAt(indexPath) as! TopicDetailWebViewContentCell
//            self.webViewContentCell?.parentScrollView = self
//            if self.webViewContentCell!.contentHeightChanged == nil {
//                self.webViewContentCell!.contentHeightChanged = webCellheightChanged
//            }
//            if self.webViewContentCell == nil {
//                self.webViewContentCell = super.cellAt(indexPath) as! TopicDetailWebViewContentCell
//                self.webViewContentCell?.parentScrollView = self
//            }
//            else {
//                return self.webViewContentCell!
//            }
//            if self.webViewContentCell!.contentHeightChanged == nil {
//                self.webViewContentCell!.contentHeightChanged = webCellheightChanged
////                self.webViewContentCell!.contentHeightChanged = { [weak self] (height:CGFloat) -> Void  in
////                    if let weakSelf = self {
////                        //在cell显示在屏幕时更新，否则会崩溃会崩溃会崩溃
////                        //另外刷新清空旧cell,重新创建这个cell ,所以 contentHeightChanged 需要判断cell是否为nil
////                        if let cell = weakSelf.webViewContentCell, weakSelf.visibleCells.contains(cell) {
////                            self?.beginUpdates()
////                            self?.endUpdates()
////                        }
////                    }
////                }
//            }
            return self.webViewContentCell!
        }
        if indexPath.section == 1 {
            let cell = super.cellAt(indexPath)  as! TopicDetailCommentCell
            //            let cell = getCell(tableView!, cell: TopicDetailCommentCell.self, indexPath: indexPath)
            cell.bind(self.commentsArray[indexPath.row])
            return cell
        }
//        let _section = TopicDetailTableViewSection(rawValue: indexPath.section)!
//        var _headerComponent = TopicDetailHeaderComponent.other
//        if let headerComponent = TopicDetailHeaderComponent(rawValue: indexPath.row) {
//            _headerComponent = headerComponent
//        }
//
//        switch _section {
//        case .header:
//            switch _headerComponent {
//            case .title:
//                //帖子标题
//                
//            case .webViewContent:
//                //帖子内容
//                          case .other:
//                let cell = super.cellAt(indexPath) as! BaseDetailTableViewCell
//                cell.detailMarkHidden = true
//                cell.titleLabel.text = self.model?.topicCommentTotalCount
//                cell.titleLabel.font = v2Font(12)
//                cell.backgroundColor = V2EXColor.colors.v2_CellWhiteBackgroundColor
////                cell.backgroundColor = .blue
//                cell.separator.image = createImageWithColor(self.backgroundColor!)
//                return cell
////            case .other:
////                return UITableViewCell()
//            }
//        case .comment:
//            let cell = super.cellAt(indexPath)  as! TopicDetailCommentCell
////            let cell = getCell(tableView!, cell: TopicDetailCommentCell.self, indexPath: indexPath)
//            cell.bind(self.commentsArray[indexPath.row])
//            return cell
//            
//        }
        return UITableViewCell();
    }
    func nodeClick() {
        Msg.send("openNodeTopicList",[self.model?.node,self.model?.nodeName])
    }
}

//MARK: - V2ActivityView
enum V2ActivityViewTopicDetailAction : Int {
    case block = 0, favorite, grade, explore
}
//class ActivityViewDS : UIViewController,V2ActivityViewDataSource{

extension TopicDetailViewController: V2ActivityViewDataSource {
    func V2ActivityView(_ activityView: V2ActivityViewController, numberOfCellsInSection section: Int) -> Int {
        return 4
    }
    func V2ActivityView(_ activityView: V2ActivityViewController, ActivityAtIndexPath indexPath: IndexPath) -> V2Activity {
        return V2Activity(title: [
            NSLocalizedString("ignore"),
            NSLocalizedString("favorite"),
            NSLocalizedString("thank"),
            "Safari"][indexPath.row], image: UIImage(named: ["ic_block_48pt","ic_grade_48pt","ic_favorite_48pt","ic_explore_48pt"][indexPath.row])!)
    }
    func V2ActivityView(_ activityView:V2ActivityViewController ,heightForFooterInSection section: Int) -> CGFloat{
        return 45
    }
    func V2ActivityView(_ activityView:V2ActivityViewController ,viewForFooterInSection section: Int) ->UIView?{
        let view = UIView()
        view.backgroundColor = V2EXColor.colors.v2_ButtonBackgroundColor
        
        let label = UILabel()
        label.font = v2Font(18)
        label.text = NSLocalizedString("reply2")
        label.textAlignment = .center
        label.textColor = UIColor.white
        view.addSubview(label)
        label.snp.makeConstraints{ (make) -> Void in
            make.top.right.bottom.left.equalTo(view)
        }
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(reply)))
        
        return view
    }
    
    func V2ActivityView(_ activityView: V2ActivityViewController, didSelectRowAtIndexPath indexPath: IndexPath) {
        activityView.dismiss()
        let action = V2ActivityViewTopicDetailAction(rawValue: indexPath.row)!
        
        guard User.shared.isLogin
            // 用safari打开是不用登录的
            || action == V2ActivityViewTopicDetailAction.explore else {
            V2Inform("请先登录")
            return;
        }
        let topicDetailViewController = self
        switch action {
        case .block:
            V2BeginLoading()
            if let topicId = topicDetailViewController._tableView.model?.topicId  {
                TopicDetailModel.ignoreTopicWithTopicId(topicId, completionHandler: {[weak self] (response) -> Void in
                    if response.success {
                        V2Success("忽略成功")
                        topicDetailViewController.navigationController?.popViewController(animated: true)
                        topicDetailViewController.ignoreTopicHandler?(topicId)
                    }
                    else{
                        V2Error("忽略失败")
                    }
                    })
            }
        case .favorite:
            V2BeginLoading()
            if let topicId = topicDetailViewController._tableView.model?.topicId ,let token = topicDetailViewController._tableView.model?.token {
                TopicDetailModel.favoriteTopicWithTopicId(topicId, token: token, completionHandler: { (response) -> Void in
                    if response.success {
                        V2Success("收藏成功")
                    }
                    else{
                        V2Error("收藏失败")
                    }
                })
            }
        case .grade:
            V2BeginLoading()
            if let topicId = topicDetailViewController._tableView.model?.topicId ,let token = topicDetailViewController._tableView.model?.token {
                TopicDetailModel.topicThankWithTopicId(topicId, token: token, completionHandler: { (response) -> Void in
                    if response.success {
                        V2Success("成功送了一波铜币")
                    }
                    else{
                        V2Error("没感谢成功，再试一下吧")
                    }
                })
            }
        case .explore:
            UIApplication.shared.openURL(URL(string: V2EXURL + "t/" + topicDetailViewController._tableView.model!.topicId!)!)
        }
    }
    
    func reply(){
        let topicDetailViewController = self
        topicDetailViewController.activityView?.dismiss()
        Msg.send("replyTopic", [topicDetailViewController._tableView.model!,topicDetailViewController.navigationController])
    }
    
}
fileprivate class Sheet : UIView,UIActionSheetDelegate {
    var table : Table1!
    var viewControler : UIViewController?
    fileprivate func ActionSheet(_ indexPath:IndexPath, _ vc : UIViewController,_ table :Table1 ) {
        self.table = table
        self.viewControler = vc
        let sheet: UIAlertController = UIAlertController(title:nil, message:nil, preferredStyle:UIAlertControllerStyle.actionSheet)
        sheet.addAction(UIAlertAction(title:"回复", style:UIAlertActionStyle.default, handler:{ action in
            self.replyComment(indexPath.row)
        }))
        sheet.addAction(UIAlertAction(title:"感谢", style:UIAlertActionStyle.default, handler:{ action in
            self.thankComment(indexPath.row)
        }))
        sheet.addAction(UIAlertAction(title:"查看对话", style:UIAlertActionStyle.default, handler:{ action in
            self.relevantComment(indexPath.row)
        }))
        sheet.addAction(UIAlertAction(title:"取消", style:UIAlertActionStyle.cancel, handler:nil))
        vc.present(sheet, animated:true, completion:nil)
    }
    func selectedRowWithActionSheet(_ indexPath:IndexPath, _ vc : UIViewController,_ table : Table1){
        ActionSheet(indexPath,vc,table)
    }
    func replyComment(_ row:Int){
        User.shared.ensureLoginWithHandler {
            let item = table.commentsArray[row as Int]
            Msg.send("replyComment", [viewControler as Any,item.userName as Any,table.model!])
        }
    }
    func thankComment(_ row:Int){
        guard User.shared.isLogin else {
            V2Inform("请先登录")
            return;
        }
        let item = table.commentsArray[row as Int]
        if item.replyId == nil {
            V2Error("回复replyId为空")
            return;
        }
        if table.model?.token == nil {
            V2Error("帖子token为空")
            return;
        }
        item.favorites += 1
        table.reloadRows(at: [IndexPath(row: row as Int, section: 1)], with: .none)
        
        TopicCommentModel.replyThankWithReplyId(item.replyId!, token: table.model!.token!) {
            [weak item, weak self](response) in
            if response.success {
            }
            else{
                V2Error("感谢失败了")
                //失败后 取消增加的数量
                item?.favorites -= 1
                self!.table?.reloadRows(at: [IndexPath(row: row as Int, section: 1)], with: .none)
            }
        }
    }
    func relevantComment(_ row:Int){
        let item = table.commentsArray[row as Int]
        let relevantComments = TopicCommentModel.getRelevantCommentsInArray(table.commentsArray, firstComment: item)
        if relevantComments.count <= 0 {
            return;
        }
        Msg.send("relevantComment", [viewControler as Any,relevantComments])
    }
}
fileprivate class TopicDetailHeaderCell: TJCell {
    fileprivate override func load(_ data: TableDataSource, _ item: TableDataSourceItem, _ indexPath: IndexPath) {
        let model = TopicDetailModel()
        model.fromDict(item)
        self.userNameLabel.text = model.userName;
        self.dateAndLastPostUserLabel.text = model.date
        self.topicTitleLabel.text = model.topicTitle;
        
        if let avata = model.avata {
            self.avatarImageView.fin_setImageWithUrl(URL(string: "https:" + avata)!, placeholderImage: nil, imageModificationClosure: fin_defaultImageModification())
        }
        
        if let node = model.nodeName{
            self.nodeNameLabel.text = "  " + node + "  "
        }
    }
    //fileprivate class TopicDetailHeaderCell: UITableViewCell {
    /// 头像
    var avatarImageView: UIImageView = {
        let imageview = UIImageView();
        imageview.contentMode=UIViewContentMode.scaleAspectFit;
        imageview.layer.cornerRadius = 3;
        imageview.layer.masksToBounds = true;
        return imageview
    }()
    /// 用户名
    var userNameLabel: UILabel = {
        let label = UILabel();
        label.textColor = V2EXColor.colors.v2_TopicListUserNameColor;
        label.font=v2Font(14);
        return label
    }()
    /// 日期 和 最后发送人
    var dateAndLastPostUserLabel: UILabel = {
        let label = UILabel();
        label.textColor=V2EXColor.colors.v2_TopicListDateColor;
        label.font=v2Font(12);
        return label
    }()
    
    /// 节点
    var nodeNameLabel: UILabel = {
        let label = UILabel();
        label.textColor = V2EXColor.colors.v2_TopicListDateColor
        label.font = v2Font(11)
        label.backgroundColor = V2EXColor.colors.v2_NodeBackgroundColor
        label.layer.cornerRadius=2;
        label.clipsToBounds = true
        label.isUserInteractionEnabled = true
        return label
    }()
    
    /// 帖子标题
    //    var topicTitleLabel: UILabel = {
    //        let label = V2SpacingLabel();
    //        label.textColor = V2EXColor.colors.v2_TopicListTitleColor;
    //        label.font = v2Font(17);
    //        label.numberOfLines = 0;
    //        label.preferredMaxLayoutWidth = SCREEN_WIDTH-24;
    //        return label
    //    }()
    var topicTitleLabel: UILabel = TopicTitleLabel()
    
    
    /// 装上面定义的那些元素的容器
    var contentPanel:UIView = {
        let view = UIView()
        view.backgroundColor = V2EXColor.colors.v2_CellWhiteBackgroundColor
        return view
    }()
    
    weak var itemModel:TopicDetailModel?
    var nodeClickHandler:(() -> Void)?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier);
//        self.setup();
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override func setup()->Void{
        self.selectionStyle = .none
        self.backgroundColor=V2EXColor.colors.v2_backgroundColor;
        
        self.contentView.addSubview(self.contentPanel);
        self.contentPanel.addSubview(self.avatarImageView);
        self.contentPanel.addSubview(self.userNameLabel);
        self.contentPanel.addSubview(self.dateAndLastPostUserLabel);
        self.contentPanel.addSubview(self.nodeNameLabel)
        self.contentPanel.addSubview(self.topicTitleLabel);
        
        self.setupLayout()
        
        //点击用户头像，跳转到用户主页
        self.avatarImageView.isUserInteractionEnabled = true
        self.userNameLabel.isUserInteractionEnabled = true
        var userNameTap = UITapGestureRecognizer(target: self, action: #selector(TopicDetailHeaderCell.userNameTap(_:)))
        self.avatarImageView.addGestureRecognizer(userNameTap)
        userNameTap = UITapGestureRecognizer(target: self, action: #selector(TopicDetailHeaderCell.userNameTap(_:)))
        self.userNameLabel.addGestureRecognizer(userNameTap)
        self.nodeNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(nodeClick)))
        
    }
    
    fileprivate func setupLayout(){
        self.avatarImageView.snp.makeConstraints{ (make) -> Void in
            make.left.top.equalTo(self.contentPanel).offset(12);
            make.width.height.equalTo(35);
        }
        self.userNameLabel.snp.makeConstraints{ (make) -> Void in
            make.left.equalTo(self.avatarImageView.snp.right).offset(10);
            make.top.equalTo(self.avatarImageView);
        }
        self.dateAndLastPostUserLabel.snp.makeConstraints{ (make) -> Void in
            make.bottom.equalTo(self.avatarImageView);
            make.left.equalTo(self.userNameLabel);
        }
        self.nodeNameLabel.snp.makeConstraints{ (make) -> Void in
            make.centerY.equalTo(self.userNameLabel);
            make.right.equalTo(self.contentPanel.snp.right).offset(-10)
            make.bottom.equalTo(self.userNameLabel).offset(1);
            make.top.equalTo(self.userNameLabel).offset(-1);
        }
        self.topicTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.avatarImageView.snp.bottom).offset(12);
            make.left.equalTo(self.avatarImageView);
            make.right.equalTo(self.contentPanel).offset(-12);
        }
        self.contentPanel.snp.makeConstraints{ (make) -> Void in
            make.top.left.right.equalTo(self.contentView);
            make.bottom.equalTo(self.topicTitleLabel.snp.bottom).offset(12);
            make.bottom.equalTo(self.contentView).offset(SEPARATOR_HEIGHT * -1);
        }
    }
    func nodeClick() {
        nodeClickHandler?()
    }
    func userNameTap(_ sender:UITapGestureRecognizer) {
        if let _ = self.itemModel , let username = itemModel?.userName {
            Msg.send("pushMemberViewController", [username])
        }
    }
    
    func bind(_ model:TopicDetailModel){
        
        self.itemModel = model
        
        self.userNameLabel.text = model.userName;
        self.dateAndLastPostUserLabel.text = model.date
        self.topicTitleLabel.text = model.topicTitle;
        
        if let avata = model.avata {
            self.avatarImageView.fin_setImageWithUrl(URL(string: "https:" + avata)!, placeholderImage: nil, imageModificationClosure: fin_defaultImageModification())
        }
        
        if let node = model.nodeName{
            self.nodeNameLabel.text = "  " + node + "  "
        }
    }
}
