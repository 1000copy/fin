import UIKit
import FXBlurView
import KVOController
import Kingfisher
class LeftViewController: UIViewController{
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = V2EXColor.colors.v2_backgroundColor;
        let _ = FrostedView(self.view)
        self.view.addSubview(LeftTable.shared);
        LeftTable.shared.snp.makeConstraints{ (make) -> Void in
            make.top.right.bottom.left.equalTo(self.view);
        }
        if User.shared.isLogin {
           UserModel.refresh(User.shared.username!)
        }
        
    }
}
fileprivate class FrostedView : FXBlurView{
    init(_ owner : UIView) {
        super.init(frame: CGRect.zero)
        isDynamic = false
        tintColor = UIColor.black
        frame = owner.frame
        underlyingView = BackImage(owner)
        owner.addSubview(self)
        Msg.observe(self, #selector(themeChanged), "ThemeChanged")
    }
    func themeChanged(){
        self.updateAsynchronously(true, completion: nil)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    class BackImage :UIImageView{
        init(_ owner : UIView) {
            super.init(frame: CGRect.zero)
            self.frame = owner.frame
            self.contentMode = .scaleToFill
            owner.addSubview(self)
            self.thmemChangedHandler = {[weak self] (style) -> Void in
                if V2EXColor.sharedInstance.style == V2EXColor.V2EXColorStyleDefault {
                    self?.image = UIImage(named: "32.jpg")
                }else{
                    self?.image = UIImage(named: "12.jpg")
                }
                Msg.send("ThemeChanged")
            }
        }
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}


fileprivate class LeftTable : TableBase{
    let data = [
        [
            [HeadCell.self,"url","login"]
        ],
        [
            [ MeCell.self, "me","ic_face"],
            [ NotifyCell.self, "me","ic_face"],
            [ FavoriteCell.self, "favorites","ic_turned_in_not"]
        ],
        [
            [ NodeCell.self, "me","ic_face"],
            [ MoreCell.self, "me","ic_face"],
            ]
    ]
    static var shared_ : LeftTable!
    static var shared : LeftTable{
        get{
            if shared_ == nil{
                shared_ = LeftTable()
            }
            return shared_
        }
    }
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame:frame,style:style)
        backgroundColor = UIColor.clear
        estimatedRowHeight=100;
        separatorStyle = .none;
        var arr : [CellBase.Type] = []
        for item in data{
            for i in item{
                let cb = i[0]
                arr.append(cb as! CellBase.Type )
            }
        }
        registerCells(arr)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func sectionCount() -> Int {
        return data.count
    }
    override func rowCount(_ section: Int) -> Int {
        return data[section].count
    }
    override func rowHeight(_ indexPath: IndexPath) -> CGFloat {
        if (indexPath.section == 1 && indexPath.row == 2)
            
        {
            return 55+10
        }
        return [180,55+SEPARATOR_HEIGHT,55+SEPARATOR_HEIGHT][indexPath.section]
    }
    override func cellAt(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeneCell(data[indexPath.section][indexPath.row][0] as! CellBase.Type, indexPath) as CellBase
        cell.load(data[indexPath.section][indexPath.row])
        return cell
    }
    override func didSelectRowAt(_ indexPath: IndexPath) {
        let cell = self.cellForRow(at: indexPath)
        if let p  = cell as? CellBase {
            p.action(indexPath)
        }
        
    }
}
fileprivate class AvatarImageView : ImageBase{
    var owner : UIView
    init(_ owner : UIView) {
        self.owner = owner
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor(white: 0.9, alpha: 0.3)
        self.layer.borderWidth = 1.5
        self.layer.borderColor = UIColor(white: 1, alpha: 0.6).cgColor
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 38
        owner.addSubview(self)
        self.snp.makeConstraints{ (make) -> Void in
            make.centerX.equalTo(owner)
            make.centerY.equalTo(owner).offset(-8)
            make.width.height.equalTo(self.layer.cornerRadius * 2)
        }
    }
    required convenience init(imageLiteralResourceName name: String) {
        fatalError("init(imageLiteralResourceName:) has not been implemented")
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func userChanged(){
        if let avatar = User.shared.user?.avatar_large{
                kfImage("https:"+avatar){
                    if !User.shared.isLogin {
                        self.image = nil
                    }
                }
        }
        else { //没有登录
            self.image = nil
        }
    }
}
//protocol CellAction{
//    func action(_ indexPath : IndexPath)-> Void
//}
//class CellBase : UITableViewCell ,CellAction{
//    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier);
//        self.setup();
//    }
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//    }
//    func setup(){
//    }
//    func load(){
//    }
//    func action(_ indexPath : IndexPath){
//    }
//}
fileprivate class HeadCell: CellBase {
    override func action(_ indexPath : IndexPath){
        print(indexPath)
        if !User.shared.isLogin {
            Msg.send("presentLoginViewController")
        }else{
            Msg.send("pushMyCenterViewController",[User.shared.username])
        }
    }
    /// 头像
    var avatarImageView: AvatarImageView!
    /// 用户名
    var userNameLabel: UILabel!
    override func setup()->Void{
        avatarImageView =  AvatarImageView(self.contentView)
        userNameLabel =  UILabel()
        self.contentView.addSubview(userNameLabel)
        self.backgroundColor = UIColor.clear
        self.selectionStyle = .none
        self.userNameLabel.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(self.avatarImageView.snp.bottom).offset(10)
            make.centerX.equalTo(self.avatarImageView)
        }
        self.kvoController.observe(User.shared, keyPath: "username", options: [.initial , .new]){
            [weak self] (observe, observer, change) -> Void in
            if let weakSelf = self {
                weakSelf.avatarImageView.userChanged()
                weakSelf.userNameLabel.text = "请先登录"
                if let user = User.shared.user {
                    weakSelf.userNameLabel.text = user.username
                }
            }
        }
        self.thmemChangedHandler = {[weak self] (style) -> Void in
            self?.userNameLabel.textColor = V2EXColor.colors.v2_TopicListUserNameColor
        }
    }    
}
fileprivate class NodeCell:LeftNodeTableViewCell{
    override func action(_ indexPath : IndexPath){
        Msg.send("pushNodesViewController")
        Msg.send("closeDrawer")
    }
    override fileprivate func setup() {
        super.setup()
        nodeNameLabel.text = NSLocalizedString("nodes")
        nodeImageView.image = UIImage.imageUsedTemplateMode("ic_navigation")
    }
}
fileprivate class MoreCell:LeftNodeTableViewCell{
    override func action(_ indexPath : IndexPath){
        Msg.send("pushMoreViewController")
        Msg.send("closeDrawer")
    }
    override fileprivate func setup() {
        super.setup()
        nodeNameLabel.text = NSLocalizedString("more")
        nodeImageView.image = UIImage.imageUsedTemplateMode("ic_settings_input_svideo")
    }
}
fileprivate class MeCell:LeftNodeTableViewCell{
    override func action(_ indexPath : IndexPath){
        if !User.shared.isLogin {
            Msg.send("presentLoginViewController")
            return
        }
        Msg.send("pushMyCenterViewController",[User.shared.username])
        Msg.send("closeDrawer")

    }
    override fileprivate func setup() {
        super.setup()
    }
    fileprivate override func load(_ data: Any) {
        let a = (data) as! [Any]
        nodeNameLabel.text = NSLocalizedString(a[1] as! String)
        nodeImageView.image = UIImage.imageUsedTemplateMode(a[2] as! String)
    }
}
fileprivate class FavoriteCell:LeftNodeTableViewCell{
    override func action(_ indexPath : IndexPath){
        if !User.shared.isLogin {
            Msg.send("presentLoginViewController")
            return
        }
        Msg.send("pushFavoritesViewController")
         Msg.send("closeDrawer")
    }
    override fileprivate func setup() {
        super.setup()
        nodeNameLabel.text =  NSLocalizedString("favorites")
        nodeImageView.image = UIImage.imageUsedTemplateMode("ic_turned_in_not")
    }
}
fileprivate class LeftNodeTableViewCell: CellBase {
    var nodeImageView: UIImageView = UIImageView()
    var nodeNameLabel: UILabel = {
        let label =  UILabel()
        label.font = v2Font(16)
        return label
    }()
    var panel = UIView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier);
        self.setup();
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func setup(){
        self.selectionStyle = .none
        self.backgroundColor = UIColor.clear
        
        self.contentView.addSubview(panel)
        panel.addSubview(self.nodeImageView)
        panel.addSubview(self.nodeNameLabel)
        
        panel.snp.makeConstraints{ (make) -> Void in
            make.left.top.right.equalTo(self.contentView)
            make.height.equalTo(55)
        }
        self.nodeImageView.snp.makeConstraints{ (make) -> Void in
            make.centerY.equalTo(panel)
            make.left.equalTo(panel).offset(20)
            make.width.height.equalTo(25)
        }
        self.nodeNameLabel.snp.makeConstraints{ (make) -> Void in
            make.left.equalTo(self.nodeImageView.snp.right).offset(20)
            make.centerY.equalTo(self.nodeImageView)
        }
        
        self.thmemChangedHandler = {[weak self] (style) -> Void in
            self?.configureColor()
        }
    }
    func configureColor(){
        self.panel.backgroundColor = V2EXColor.colors.v2_LeftNodeBackgroundColor
        self.nodeImageView.tintColor =  V2EXColor.colors.v2_LeftNodeTintColor
        self.nodeNameLabel.textColor = V2EXColor.colors.v2_LeftNodeTintColor
    }
}
fileprivate class NotifyCell : LeftNodeTableViewCell{
    override func action(_ indexPath : IndexPath){
        if !User.shared.isLogin {
            Msg.send("presentLoginViewController")
            return
        }
        Msg.send("pushNotificationsViewController")
        Msg.send("closeDrawer")
    }
    var notifictionCountLabel:UILabel = {
        let label = UILabel()
        label.font = v2Font(10)
        label.textColor = UIColor.white
        label.layer.cornerRadius = 7
        label.layer.masksToBounds = true
        label.backgroundColor = V2EXColor.colors.v2_NoticePointColor
        return label
    }()
    override func setup() {
        super.setup()
        nodeImageView.image = UIImage.imageUsedTemplateMode("ic_notifications_none")
        self.nodeNameLabel.text = NSLocalizedString("notifications")
        
        self.contentView.addSubview(self.notifictionCountLabel)
        self.notifictionCountLabel.snp.makeConstraints{ (make) -> Void in
            make.centerY.equalTo(self.nodeNameLabel)
            make.left.equalTo(self.nodeNameLabel.snp.right).offset(5)
            make.height.equalTo(14)
        }
        
        self.kvoController.observe(User.shared, keyPath: "notificationCount", options: [.initial,.new]) {  [weak self](cell, clien, change) -> Void in
            if User.shared.notificationCount > 0 {
                self?.notifictionCountLabel.text = "   \(User.shared.notificationCount)   "
            }
            else{
                self?.notifictionCountLabel.text = ""
            }
        }
    }
}
