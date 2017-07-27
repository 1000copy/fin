import YYText
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
    fileprivate var _tableView :TableTopicDetail!
    fileprivate var tableView: TableTopicDetail {
        get{
            if(_tableView != nil){
                return _tableView!;
            }
            _tableView = TableTopicDetail();
            //            _tableView.viewControler = self
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
fileprivate class TopicTitleLabel :V2SpacingLabel{
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

fileprivate class TableTopicDetail:  TJTable{
    var topicId = "0"
    var currentPage = 1
    fileprivate var model:TopicDetailModel?
    fileprivate var commentsArray:[TopicCommentModel] = []
    fileprivate var webViewContentCell:TopicDetailWebViewContentCell?
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame,style:style)
        separatorStyle = .none;
        backgroundColor = V2EXColor.colors.v2_backgroundColor
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func sectionCount() -> Int {
        return 2
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
        if indexPath.section == 1 {
            item = (commentsArray[indexPath.row].toDict())
        }
        return item
    }
    override func rowCount(_ section: Int) -> Int {
        if section == 1 {
            return self.commentsArray.count;
        }
        return self.model != nil ? 2 : 0
    }
    override func rowHeight(_ indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            return TopicTitleLabel.heightFor(self.model!.topicTitle) + 12 + 48 + 12
        }
        if indexPath.section == 0 && indexPath.row == 1 {
            if let height =  self.webViewContentCell?.contentHeight , height > 0 {
                return height
            }
            else {
                return 1
            }
        }
        return self.commentsArray[indexPath.row].getHeight()
    }
    override func cellTypeAt(_ indexPath:IndexPath) -> UITableViewCell.Type{
        if indexPath.section == 0 {
            let a :[UITableViewCell.Type] = [TopicDetailHeaderCell.self,TopicDetailWebViewContentCell.self]
            return a[indexPath.row]
        }
        return TopicDetailCommentCell.self
    }
    override func cellAt(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = super.cellAt(indexPath)
        if indexPath.section == 0 && indexPath.row == 1 {
            // 此对象随后还有事件（cellHeightChanged）执行，因此必须保留引用，以免实例被释放，后面就执行不了。
            webViewContentCell = cell as? TopicDetailWebViewContentCell
        }
        return cell
    }
}

//MARK: - V2ActivityView
enum V2ActivityViewTopicDetailAction : Int {
    case block = 0, favorite, grade, explore
}
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
                TopicDetailModel.ignoreTopicWithTopicId(topicId, completionHandler: {(response) -> Void in
                    if response.success {
                        V2Success("忽略成功")
                        let _ = topicDetailViewController.navigationController?.popViewController(animated: true)
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
    var table : TableTopicDetail!
    var viewControler : UIViewController?
    fileprivate func ActionSheet(_ indexPath:IndexPath, _ vc : UIViewController,_ table :UITableView ) {
        self.table = table as! TableTopicDetail
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
    func selectedRowWithActionSheet(_ indexPath:IndexPath, _ vc : UIViewController,_ table : TableTopicDetail){
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
extension TJCell {
    var ownerTableView: UITableView? {
        var view = self.superview
        while (view != nil && view!.isKind(of: UITableView.self) == false) {
            view = view!.superview
        }
        return view as? UITableView
    }
}
fileprivate class TopicDetailHeaderCell: TJCell {
    var model : TopicDetailModel!
    //    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    //        super.init(style: style, reuseIdentifier: reuseIdentifier);
    //        //        self.setup();
    //    }
    //    required init?(coder aDecoder: NSCoder) {
    //        super.init(coder: aDecoder)
    //    }
    fileprivate override func load(_ data: PCTableDataSource, _ item: TableDataSourceItem, _ indexPath: IndexPath) {
        model = TopicDetailModel()
        model.fromDict(item)
        self._user.text = model.userName;
        self._date.text = model.date
        self.topicTitleLabel.text = model.topicTitle;
        
        if let avata = model.avata {
            self._avatar.fin_setImageWithUrl(URL(string: "https:" + avata)!, placeholderImage: nil, imageModificationClosure: fin_defaultImageModification())
        }
        
        if let node = model.nodeName{
            self._node.text = "  " + node + "  "
        }
    }
    //fileprivate class TopicDetailHeaderCell: UITableViewCell {
    /// 头像
    var _avatar: TJImage = {
        let imageview = TJImage();
        imageview.contentMode=UIViewContentMode.scaleAspectFit;
        imageview.layer.cornerRadius = 3;
        imageview.layer.masksToBounds = true;
        return imageview
    }()
    /// 用户名
    var _user: TJLabel = {
        let label = TJLabel();
        label.textColor = V2EXColor.colors.v2_TopicListUserNameColor;
        label.font=v2Font(14);
        return label
    }()
    /// 日期 和 最后发送人
    var _date: UILabel = {
        let label = UILabel();
        label.textColor=V2EXColor.colors.v2_TopicListDateColor;
        label.font=v2Font(12);
        return label
    }()
    
    /// 节点
    var _node: UILabel = {
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
    var _panel:TJView = {
        let view = TJView()
        view.backgroundColor = V2EXColor.colors.v2_CellWhiteBackgroundColor
        return view
    }()
    
    var nodeClickHandler:(() -> Void)?
    override func onLoad()->Void{
        self.selectionStyle = .none
        self.backgroundColor=V2EXColor.colors.v2_backgroundColor;
        
        self.contentView.addSubview(self._panel);
        self._panel.addSubview(self._avatar);
        self._panel.addSubview(self._user);
        self._panel.addSubview(self._date);
        self._panel.addSubview(self._node)
        self._panel.addSubview(self.topicTitleLabel);
        //点击用户头像，跳转到用户主页
        self._avatar.tap = self.userNameTap
        self._user.tap = self.userNameTap
        self._node.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(nodeClick)))
        
    }
    
    override func onLayout() {
        self._avatar.snp.makeConstraints{ (make) -> Void in
            make.left.top.equalTo(self._panel).offset(12);
            make.width.height.equalTo(35);
        }
        self._user.snp.makeConstraints{ (make) -> Void in
            make.left.equalTo(self._avatar.snp.right).offset(10);
            make.top.equalTo(self._avatar);
        }
        self._date.snp.makeConstraints{ (make) -> Void in
            make.bottom.equalTo(self._avatar);
            make.left.equalTo(self._user);
        }
        self._node.snp.makeConstraints{ (make) -> Void in
            make.centerY.equalTo(self._user);
            make.right.equalTo(self._panel.snp.right).offset(-10)
            make.bottom.equalTo(self._user).offset(1);
            make.top.equalTo(self._user).offset(-1);
        }
        self.topicTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self._avatar.snp.bottom).offset(12);
            make.left.equalTo(self._avatar);
            make.right.equalTo(self._panel).offset(-12);
        }
        self._panel.snp.makeConstraints{ (make) -> Void in
            make.top.left.right.equalTo(self.contentView);
            make.bottom.equalTo(self.topicTitleLabel.snp.bottom).offset(12);
            make.bottom.equalTo(self.contentView).offset(SEPARATOR_HEIGHT * -1);
        }
    }
    func nodeClick() {
        Msg.send("openNodeTopicList",[self.model?.node,self.model?.nodeName])
    }
    func userNameTap() {
        if let _ = self.model , let username = model?.userName {
            Msg.send("pushMemberViewController", [username])
        }
    }
}


class TopicDetailCommentCell: TJCell{
    override func load(_ data: PCTableDataSource, _ item: TableDataSourceItem, _ indexPath: IndexPath) {
        let model = TopicCommentModel ()
        model.fromDict(item)
        bind(model)
    }
    override func action(_ indexPath: IndexPath) {
        let sheet = Sheet()
        sheet.ActionSheet(indexPath, ownerViewController!, ownerTableView!)
    }
    func bind(_ model:TopicCommentModel){
        
        if let avata = model.avata {
            self._avatar.fin_setImageWithUrl(URL(string: "https:" + avata)!, placeholderImage: nil, imageModificationClosure: fin_defaultImageModification())
        }
        
        if self.itemModel?.number == model.number && self.itemModel?.userName == model.userName {
            return;
        }
        
        self._user.text = model.userName;
        self.dateLabel.text = String(format: "%i楼  %@", model.number, model.date ?? "")
        
        if let layout = model.getTextLayout() {
            self.commentLabel.textLayout = layout
        }
        self.favoriteIconView.isHidden = model.favorites <= 0
        self.favoriteLabel.text = model.favorites <= 0 ? "" : "\(model.favorites)"
        self.itemModel = model
    }
    /// 头像
    var _avatar: TJImage = {
        let _avatar = TJImage()
        _avatar.contentMode=UIViewContentMode.scaleAspectFit
        _avatar.layer.cornerRadius = 3
        _avatar.layer.masksToBounds = true
        return _avatar
    }()
    /// 用户名
    var _user: TJLabel = {
        let _user = TJLabel()
        _user.textColor = V2EXColor.colors.v2_TopicListUserNameColor
        _user.font=v2Font(14)
        return _user
    }()
    /// 日期 和 最后发送人
    var dateLabel: UILabel = {
        let dateLabel = UILabel()
        dateLabel.textColor=V2EXColor.colors.v2_TopicListDateColor
        dateLabel.font=v2Font(12)
        return dateLabel
    }()
    
    /// 回复正文
    var commentLabel: YYLabel = {
        let commentLabel = YYLabel();
        commentLabel.textColor=V2EXColor.colors.v2_TopicListTitleColor;
        commentLabel.font = v2Font(14);
        commentLabel.numberOfLines = 0;
        commentLabel.displaysAsynchronously = true
        return commentLabel
    }()
    
    /// 装上面定义的那些元素的容器
    var _panel: TJView = {
        let view = TJView()
        view.backgroundColor = V2EXColor.colors.v2_CellWhiteBackgroundColor
        return view
    }()
    
    //评论喜欢数
    var favoriteIconView:UIImageView = {
        let favoriteIconView = UIImageView(image: UIImage.imageUsedTemplateMode("ic_favorite_18pt")!)
        favoriteIconView.tintColor = V2EXColor.colors.v2_TopicListDateColor;
        favoriteIconView.contentMode = .scaleAspectFit
        favoriteIconView.isHidden = true
        return favoriteIconView
    }()
    
    var favoriteLabel:UILabel = {
        let favoriteLabel = UILabel()
        favoriteLabel.textColor = V2EXColor.colors.v2_TopicListDateColor;
        favoriteLabel.font = v2Font(10)
        return favoriteLabel
    }()
    var itemModel:TopicCommentModel?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier);
        //        self.setup();
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    func userNameTap() {
        if let _ = self.itemModel , let username = itemModel?.userName {
            Msg.send("pushMemberViewController",[username])
        }
    }
    override func onLoad()->Void{
        self.backgroundColor=V2EXColor.colors.v2_backgroundColor;
        
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = V2EXColor.colors.v2_backgroundColor
        self.selectedBackgroundView = selectedBackgroundView
        
        self.contentView.addSubview(self._panel);
        self._panel.addSubview(self._avatar);
        self._panel .addSubview(self._user);
        self._panel.addSubview(self.favoriteIconView)
        self._panel.addSubview(self.favoriteLabel)
        self._panel.addSubview(self.dateLabel);
        self._panel.addSubview(self.commentLabel);
        
        self._avatar.backgroundColor = self._panel.backgroundColor
        self._user.backgroundColor = self._panel.backgroundColor
        self.dateLabel.backgroundColor = self._panel.backgroundColor
        self.commentLabel.backgroundColor = self._panel.backgroundColor
        self.favoriteIconView.backgroundColor = self._panel.backgroundColor
        self.favoriteLabel.backgroundColor = self._panel.backgroundColor
        
        //点击用户头像，跳转到用户主页
        _avatar.tap = self.userNameTap
        _user.tap = self.userNameTap
        //长按手势
        self._panel.longPress = self.longPressHandle
        //        self._panel .addGestureRecognizer(
        //            UILongPressGestureRecognizer(target: self,
        //                                         action: #selector(TopicDetailCommentCell.longPressHandle(_:))
        //            )
        //        )
    }
    override func onLayout(){
        self._panel.snp.makeConstraints{ (make) -> Void in
            make.top.left.right.equalTo(self.contentView);
        }
        self._avatar.snp.makeConstraints{ (make) -> Void in
            make.left.top.equalTo(self.contentView).offset(12);
            make.width.height.equalTo(35);
        }
        self._user.snp.makeConstraints{ (make) -> Void in
            make.left.equalTo(self._avatar.snp.right).offset(10);
            make.top.equalTo(self._avatar);
        }
        self.favoriteIconView.snp.makeConstraints{ (make) -> Void in
            make.centerY.equalTo(self._user);
            make.left.equalTo(self._user.snp.right).offset(10)
            make.width.height.equalTo(10)
        }
        self.favoriteLabel.snp.makeConstraints{ (make) -> Void in
            make.left.equalTo(self.favoriteIconView.snp.right).offset(3)
            make.centerY.equalTo(self.favoriteIconView)
        }
        self.dateLabel.snp.makeConstraints{ (make) -> Void in
            make.bottom.equalTo(self._avatar);
            make.left.equalTo(self._user);
        }
        self.commentLabel.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(self._avatar.snp.bottom).offset(12);
            make.left.equalTo(self._avatar);
            make.right.equalTo(self._panel).offset(-12);
            make.bottom.equalTo(self._panel.snp.bottom).offset(-12)
        }
        
        self._panel.snp.makeConstraints{ (make) -> Void in
            make.bottom.equalTo(self.contentView.snp.bottom).offset(-SEPARATOR_HEIGHT);
        }
    }
    
}
//MARK: - 长按复制功能
extension TopicDetailCommentCell {
    func longPressHandle(_ longPress:UILongPressGestureRecognizer) -> Void {
        if (longPress.state == .began) {
            self.becomeFirstResponder()
            
            let item = UIMenuItem(title: "复制", action: #selector(TopicDetailCommentCell.copyText))
            
            let menuController = UIMenuController.shared
            menuController.menuItems = [item]
            menuController.arrowDirection = .down
            menuController.setTargetRect(self.frame, in: self.superview!)
            menuController.setMenuVisible(true, animated: true);
        }
    }
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if (action == #selector(TopicDetailCommentCell.copyText)){
            return true
        }
        return super.canPerformAction(action, withSender: sender);
    }
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    func copyText() -> Void {
        //        UIPasteboard.general.string = self.itemModel?.textLayout?.text.string
        UIPasteboard.general.string = self.itemModel?.getText()
    }
}
