//
//  MemberViewController.swift
//  V2ex-Swift
//
//  Created by huangfeng on 2/1/16.
//  Copyright © 2016 Fin. All rights reserved.
//
import UIKit
import FXBlurView
class MemberViewController: TJPage,UIScrollViewDelegate{
    var color:CGFloat = 0
    var username:String?
    var blockButton:UIButton?
    var followButton:UIButton?
    fileprivate var _tableView :Table!
    fileprivate var tableView: Table {
        get{
            if(_tableView != nil){
                return _tableView!;
            }
            _tableView = Table();
            _tableView.backgroundColor = UIColor.clear
            _tableView.estimatedRowHeight=200;
            _tableView.separatorStyle = UITableViewCellSeparatorStyle.none;
            return _tableView!;
        }
    }
    fileprivate weak var _loadView:UIActivityIndicatorView?
    class BlurView : TJBlur{
        override func onLoad() {
            let backgroundImageView = UIImageView(image: UIImage(named: "12.jpg"))
            backgroundImageView.frame = self.owner!.frame
            backgroundImageView.contentMode = .scaleToFill
            owner!.addSubview(backgroundImageView)
            let frostedView = FXBlurView()
            frostedView.underlyingView = backgroundImageView
            frostedView.isDynamic = false
            frostedView.frame = self.owner!.frame
            frostedView.tintColor = UIColor.black
            self.owner!.addSubview(frostedView)
        }
    }
    override func onLoad() {
        
        self.view.backgroundColor = V2EXColor.colors.v2_backgroundColor
        let _ = BlurView(self.view)
        self.view.addSubview(self.tableView);
        self.tableView.snp.makeConstraints{ (make) -> Void in
            make.top.right.bottom.left.equalTo(self.view);
        }
        self.refreshData()
    }
    func refreshData(){
        MemberModel.getMemberInfo(self.username!, completionHandler: { (response) -> Void in
            if response.success {
                if let model = response.value{
                    self.getSuccess(model)
                }
            }
        })
    }
    var titleLabel:UILabel?
    func getSuccess(_ aModel:MemberModel){
        self.tableView.model = aModel
        self.titleLabel?.text = self.tableView.model?.userName
        if self.tableView.model?.userToken != nil {
            setupBlockAndFollowButtons()
        }
        self.tableView.reloadData()
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        print(offsetY)
        navigationItem.title = offsetY > 107  ? username : ""
    }
}
fileprivate class Table : TJTable{
    var model:MemberModel?
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return [0,40,40][section]
    }
    var tableViewHeader:[UIView?] = []
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableViewHeader.count > section - 1 {
            return tableViewHeader[section-1]
        }
        let view = UIView()
        view.backgroundColor = V2EXColor.colors.v2_CellWhiteBackgroundColor
        let label = UILabel()
        label.text = [NSLocalizedString("posts"),NSLocalizedString("comments")][section - 1]
        view.addSubview(label)
        label.font = v2Font(15)
        label.textColor = V2EXColor.colors.v2_TopicListUserNameColor
        label.snp.makeConstraints{ (make) -> Void in
            make.centerY.equalTo(view)
            make.leading.equalTo(view).offset(12)
        }
        tableViewHeader.append(view)
        return view
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let id = indexPath.section == 1 ?
            self.model?.topics[indexPath.row].topicId:
            self.model?.replies[indexPath.row].topicId
        if let id = id {
            Msg.send("openTopicDetail1", [id])
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    // table begin
    override func sectionCount() -> Int {
        return 3
    }
    override func rowCount(_ section: Int) -> Int {
        if let rows = [1,self.model?.topics.count,self.model?.replies.count][section] {
            return rows
        }
        return 0
    }
    override func rowHeight(_  indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 240
        }
        else if indexPath.section == 1 {
            let str = self.model!.topics[indexPath.row].topicTitle
            return TopicTitleLabel.textHeight(str!) + 1.0*(12    +  12     +  12    +  12  + 8)
        }
        else {
            return self.fin_heightForCellWithIdentifier(MemberReplyCell.self, indexPath: indexPath) { (cell) -> Void in
                cell.bind(self.model!.replies[indexPath.row])
            }
        }
    }
    fileprivate override func cellTypes() -> [UITableViewCell.Type] {
        return [MemberHeaderCell.self,MemberTopicCell.self,MemberReplyCell.self]
    }
    fileprivate override func cellTypeAt(_ indexPath: IndexPath) -> UITableViewCell.Type {
        return cellTypes()[indexPath.section]
    }
    override func cellAt(_ indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = dequeneCell(indexPath) as MemberHeaderCell
            cell.bind(self.model)
            return cell ;
        }
        else if indexPath.section == 1 {
            let cell = dequeneCell(indexPath) as MemberTopicCell
            cell.bind(self.model!.topics[indexPath.row])
            return cell
        }
        else {
            let cell = dequeneCell(indexPath) as MemberReplyCell
            cell.bind(self.model!.replies[indexPath.row])
            return cell
        }
    }
    // table end
}
//MARK: - Block and Follow
extension MemberViewController{
    func setupBlockAndFollowButtons(){
        if !self.isMember(of: MemberViewController.self){
            return ;
        }
        let blockButton = UIButton(frame:CGRect(x: 0, y: 0, width: 26, height: 26))
        blockButton.addTarget(self, action: #selector(toggleBlockState), for: .touchUpInside)
        let followButton = UIButton(frame:CGRect(x: 0, y: 0, width: 26, height: 26))
        followButton.addTarget(self, action: #selector(toggleFollowState), for: .touchUpInside)
        let blockItem = UIBarButtonItem(customView: blockButton)
        let followItem = UIBarButtonItem(customView: followButton)
        //处理间距
        let fixedSpaceItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixedSpaceItem.width = -5
        self.navigationItem.rightBarButtonItems = [fixedSpaceItem,followItem,blockItem]
        self.blockButton = blockButton;
        self.followButton = followButton;
        refreshButtonImage()
    }
    func refreshButtonImage() {
        let blockImage = self.tableView.model?.blockState == .blocked ? UIImage(named: "ic_visibility_off")! : UIImage(named: "ic_visibility")!
        let followImage = self.tableView.model?.followState == .followed ? UIImage(named: "ic_favorite")! : UIImage(named: "ic_favorite_border")!
        self.blockButton?.setImage(blockImage.withRenderingMode(.alwaysTemplate), for: UIControlState())
        self.followButton?.setImage(followImage.withRenderingMode(.alwaysTemplate), for: UIControlState())
    }
    func toggleFollowState(){
        if(self.tableView.model?.followState == .followed){
            UnFollow()
        }
        else{
            Follow()
        }
        refreshButtonImage()
    }
    func Follow() {
        if let userId = self.tableView.model!.userId, let userToken = self.tableView.model!.userToken {
            MemberModel.follow(userId, userToken: userToken, type: .followed, completionHandler: nil)
            self.tableView.model?.followState = .followed
            V2Success("关注成功")
        }
    }
    func UnFollow() {
        if let userId = self.tableView.model!.userId, let userToken = self.tableView.model!.userToken {
            MemberModel.follow(userId, userToken: userToken, type: .unFollowed, completionHandler: nil)
            self.tableView.model?.followState = .unFollowed
            V2Success("取消关注了~")
        }
    }
    func toggleBlockState(){
        if(self.tableView.model?.blockState == .blocked){
            UnBlock()
        }
        else{
            Block()
        }
        refreshButtonImage()
    }
    func Block() {
        if let userId = self.tableView.model!.userId, let userToken = self.tableView.model!.userToken {
            MemberModel.block(userId, userToken: userToken, type: .blocked, completionHandler: nil)
            self.tableView.model?.blockState = .blocked
            V2Success("屏蔽成功")
        }
    }
    func UnBlock() {
        if let userId = self.tableView.model!.userId, let userToken = self.tableView.model!.userToken {
            MemberModel.block(userId, userToken: userToken, type: .unBlocked, completionHandler: nil)
            self.tableView.model?.blockState = .unBlocked
            V2Success("取消屏蔽了~")
        }
    }
}
fileprivate class MemberHeaderCell: UITableViewCell {
    /// 头像
    var avatarImageView: UIImageView = {
        let avatarImageView = UIImageView()
        avatarImageView.backgroundColor = UIColor(white: 0.9, alpha: 0.3)
        avatarImageView.layer.borderWidth = 1.5
        avatarImageView.layer.borderColor = UIColor(white: 1, alpha: 0.6).cgColor
        avatarImageView.layer.masksToBounds = true
        avatarImageView.layer.cornerRadius = 38
        return avatarImageView
    }()
    /// 用户名
    var userNameLabel: UILabel = {
        let userNameLabel = UILabel()
        userNameLabel.textColor = UIColor(white: 0.85, alpha: 1)
        userNameLabel.font = v2Font(16)
        userNameLabel.text = "Hello"
        return userNameLabel
    }()
    /// 签名
    var introduceLabel: UILabel = {
        let introduceLabel = UILabel()
        introduceLabel.textColor = UIColor(white: 0.75, alpha: 1)
        introduceLabel.font = v2Font(16)
        introduceLabel.numberOfLines = 2
        introduceLabel.textAlignment = .center
        return introduceLabel
    }()
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier);
        self.setup();
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    func setup()->Void{
        self.backgroundColor = UIColor.clear
        self.selectionStyle = .none
        self.contentView.addSubview(self.avatarImageView)
        self.contentView.addSubview(self.userNameLabel)
        self.contentView.addSubview(self.introduceLabel)
        self.setupLayout()
    }
    func setupLayout(){
        self.avatarImageView.snp.makeConstraints{ (make) -> Void in
            make.centerX.equalTo(self.contentView)
            make.centerY.equalTo(self.contentView).offset(-15)
            make.width.height.equalTo(self.avatarImageView.layer.cornerRadius * 2)
        }
        self.userNameLabel.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(self.avatarImageView.snp.bottom).offset(10)
            make.centerX.equalTo(self.avatarImageView)
        }
        self.introduceLabel.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(self.userNameLabel.snp.bottom).offset(5)
            make.centerX.equalTo(self.avatarImageView)
            make.left.equalTo(self.contentView).offset(15)
            make.right.equalTo(self.contentView).offset(-15)
        }
    }
    func bind(_ model:MemberModel?){
        if let model = model {
            if let avata = model.avata {
                self.avatarImageView.kf.setImage(with: URL(string: "https:" + avata)!)
            }
            self.userNameLabel.text = model.userName;
            self.introduceLabel.text = model.introduce;
        }
    }
}
fileprivate class TopicTitleLabel : UILabel{
    override init(frame: CGRect) {
        super.init(frame:frame)
        let topicTitleLabel = self
        topicTitleLabel.textColor=V2EXColor.colors.v2_TopicListTitleColor;
        topicTitleLabel.font=v2Font(15);
        topicTitleLabel.numberOfLines=0;
        topicTitleLabel.preferredMaxLayoutWidth=SCREEN_WIDTH-24
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func textHeight() -> CGFloat{
        let size = sizeThatFits(CGSize(width: self.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        return size.height
    }
    class func textHeight(_ str : String) -> CGFloat{
        let t = TopicTitleLabel()
        t.text = str
        return t.textHeight()
    }
}
fileprivate class MemberTopicCell: UITableViewCell {
    /// 日期 和 最后发送人
    var dateAndLastPostUserLabel: UILabel = {
        let dateAndLastPostUserLabel = UILabel();
        dateAndLastPostUserLabel.textColor=V2EXColor.colors.v2_TopicListDateColor;
        dateAndLastPostUserLabel.font=v2Font(12);
        return dateAndLastPostUserLabel
    }()
    /// 评论数量
    var replyCountLabel: UILabel = {
        let replyCountLabel = UILabel()
        replyCountLabel.textColor = V2EXColor.colors.v2_TopicListDateColor
        replyCountLabel.font = v2Font(12)
        return replyCountLabel
    }()
    var replyCountIconImageView: UIImageView = {
        let replyCountIconImageView = UIImageView(image: UIImage(named: "reply_n"))
        replyCountIconImageView.contentMode = .scaleAspectFit
        return replyCountIconImageView
    }()
    /// 节点
    var nodeNameLabel = TopicTitleLabel()    /// 帖子标题
    var topicTitleLabel: UILabel = {
        let topicTitleLabel=V2SpacingLabel();
        topicTitleLabel.textColor=V2EXColor.colors.v2_TopicListTitleColor;
        topicTitleLabel.font=v2Font(15);
        topicTitleLabel.numberOfLines=0;
        topicTitleLabel.preferredMaxLayoutWidth=SCREEN_WIDTH-24;
        return topicTitleLabel
    }()
    /// 装上面定义的那些元素的容器
    var contentPanel:UIView = {
        let contentPanel = UIView();
        contentPanel.backgroundColor =  V2EXColor.colors.v2_CellWhiteBackgroundColor
        return contentPanel
    }()
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier);
        self.setup();
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func setup()->Void{
        self.selectionStyle = .none
        self.backgroundColor = V2EXColor.colors.v2_backgroundColor
        self.contentView .addSubview(self.contentPanel);
        self.contentPanel.addSubview(self.dateAndLastPostUserLabel);
        self.contentPanel.addSubview(self.replyCountLabel);
        self.contentPanel.addSubview(self.replyCountIconImageView);
        self.contentPanel.addSubview(self.nodeNameLabel)
        self.contentPanel.addSubview(self.topicTitleLabel);
        self.setupLayout()
        self.dateAndLastPostUserLabel.backgroundColor = self.contentPanel.backgroundColor
        self.replyCountLabel.backgroundColor = self.contentPanel.backgroundColor
        self.replyCountIconImageView.backgroundColor = self.contentPanel.backgroundColor
        self.topicTitleLabel.backgroundColor = self.contentPanel.backgroundColor
    }
    func setupLayout(){
        self.contentPanel.snp.makeConstraints{ (make) -> Void in
            make.top.left.right.equalTo(self.contentView);
        }
        self.dateAndLastPostUserLabel.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(self.contentPanel).offset(12);
            make.left.equalTo(self.contentPanel).offset(12);
        }
        self.replyCountLabel.snp.makeConstraints{ (make) -> Void in
            make.centerY.equalTo(self.dateAndLastPostUserLabel);
            make.right.equalTo(self.contentPanel).offset(-12);
        }
        self.replyCountIconImageView.snp.makeConstraints{ (make) -> Void in
            make.centerY.equalTo(self.replyCountLabel);
            make.width.height.equalTo(18);
            make.right.equalTo(self.replyCountLabel.snp.left).offset(-2);
        }
        self.nodeNameLabel.snp.makeConstraints{ (make) -> Void in
            make.centerY.equalTo(self.replyCountLabel);
            make.right.equalTo(self.replyCountIconImageView.snp.left).offset(-4)
            make.bottom.equalTo(self.replyCountLabel).offset(1);
            make.top.equalTo(self.replyCountLabel).offset(-1);
        }
        self.topicTitleLabel.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(self.dateAndLastPostUserLabel.snp.bottom).offset(12);
            make.left.equalTo(self.dateAndLastPostUserLabel);
            make.right.equalTo(self.contentPanel).offset(-12);
        }
        self.contentPanel.snp.makeConstraints{ (make) -> Void in
            make.bottom.equalTo(self.topicTitleLabel.snp.bottom).offset(12);
            make.bottom.equalTo(self.contentView).offset(SEPARATOR_HEIGHT * -1);
        }
    }
    func bind(_ model:MemberTopicsModel){
        self.dateAndLastPostUserLabel.text = model.date
        self.topicTitleLabel.text = model.topicTitle;
        self.replyCountLabel.text = model.replies;
        if let node = model.nodeName{
            self.nodeNameLabel.text = "  " + node + "  "
        }
    }
}
fileprivate class MemberReplyCell: UITableViewCell {
    /// 操作描述
    var detailLabel: UILabel = {
        let detailLabel=V2SpacingLabel();
        detailLabel.textColor=V2EXColor.colors.v2_TopicListTitleColor;
        detailLabel.font=v2Font(14);
        detailLabel.numberOfLines=0;
        detailLabel.preferredMaxLayoutWidth=SCREEN_WIDTH-24;
        return detailLabel
    }()
    /// 回复正文
    var commentLabel: UILabel = {
        let commentLabel=V2SpacingLabel();
        commentLabel.textColor=V2EXColor.colors.v2_TopicListTitleColor;
        commentLabel.font=v2Font(14);
        commentLabel.numberOfLines=0;
        commentLabel.preferredMaxLayoutWidth=SCREEN_WIDTH-24;
        return commentLabel
    }()
    /// 回复正文的背景容器
    var commentPanel: UIView = {
        let commentPanel = UIView()
        commentPanel.layer.cornerRadius = 3
        commentPanel.layer.masksToBounds = true
        commentPanel.backgroundColor = V2EXColor.colors.v2_backgroundColor
        return commentPanel
    }()
    /// 整个cell元素的容器
    var contentPanel:UIView = {
        let contentPanel = UIView()
        contentPanel.backgroundColor =  V2EXColor.colors.v2_CellWhiteBackgroundColor
        return contentPanel
    }()
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier);
        self.setup();
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func setup()->Void{
        self.selectionStyle = .none
        self.backgroundColor = V2EXColor.colors.v2_backgroundColor
        self.contentView.addSubview(self.contentPanel)
        self.contentPanel.addSubview(self.detailLabel);
        self.contentPanel.addSubview(self.commentPanel);
        self.contentPanel.addSubview(self.commentLabel);
        self.setupLayout()
        let dropUpImageView = UIImageView()
        dropUpImageView.image = UIImage.imageUsedTemplateMode("ic_arrow_drop_up")
        dropUpImageView.contentMode = .scaleAspectFit
        dropUpImageView.tintColor = self.commentPanel.backgroundColor
        self.contentPanel.addSubview(dropUpImageView)
        dropUpImageView.snp.makeConstraints{ (make) -> Void in
            make.bottom.equalTo(self.commentPanel.snp.top)
            make.left.equalTo(self.commentPanel).offset(25)
            make.width.equalTo(10)
            make.height.equalTo(5)
        }
    }
    func setupLayout(){
        self.contentPanel.snp.makeConstraints{ (make) -> Void in
            make.top.left.right.equalTo(self.contentView);
        }
        self.detailLabel.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(self.contentPanel).offset(12);
            make.left.equalTo(self.contentPanel).offset(12);
            make.right.equalTo(self.contentPanel).offset(-12);
        }
        self.commentLabel.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(self.detailLabel.snp.bottom).offset(20);
            make.left.equalTo(self.contentPanel).offset(22);
            make.right.equalTo(self.contentPanel).offset(-22);
        }
        self.contentPanel.snp.makeConstraints{ (make) -> Void in
            make.bottom.equalTo(self.commentPanel.snp.bottom).offset(12);
            make.bottom.equalTo(self.contentView).offset(SEPARATOR_HEIGHT * -1);
        }
        self.commentPanel.snp.makeConstraints{ (make) -> Void in
            make.top.left.equalTo(self.commentLabel).offset(-10)
            make.right.bottom.equalTo(self.commentLabel).offset(10)
        }
    }
    func bind(_ model: MemberRepliesModel){
        if model.date != nil && model.title != nil {
            self.detailLabel.text = model.date! + "回复 " + model.title!
        }
        self.commentLabel.text = model.reply
    }
}
