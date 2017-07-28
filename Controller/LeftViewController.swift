import UIKit
import FXBlurView
import KVOController
import Kingfisher
class LeftViewController: TJPage{
    override func onLoad() {
        self.view.backgroundColor = V2EXColor.colors.v2_backgroundColor;
        let _ = FrostedView(self.view)
        self.view.addSubview(Table.shared);
        Table.shared.snp.makeConstraints{ (make) -> Void in
            make.top.right.bottom.left.equalTo(self.view);
        }
        if User.shared.isLogin {
            UserModelHTTP.refresh(User.shared.username!)
        }
    }
}
fileprivate class FrostedView : TJBlur{
    override func onLoad() {
        isDynamic = false
        tintColor = UIColor.black
        frame = (owner?.frame)!
        underlyingView = BackImage(owner!)
        owner?.addSubview(self)
    }
    class BackImage :TJImage{
        override func onLoad() {
            self.frame = owner.frame
            self.contentMode = .scaleToFill
            owner.addSubview(self)
            icon = "32.jpg"
        }
    }
}
class LeftTableData : TJTableDataSource{
    let data = [
        [
            [HeadCell.self,"url","login"]
        ],
        [
            [ MeCell.self, "me","ic_face"],
            [ NotifyCell.self, "notifications","ic_notifications_none"],
            [ FavoriteCell.self, "favorites","ic_turned_in_not"],
            [ NodeCell.self, "nodes","ic_navigation"],
        ],
    ]
    override func sectionCount() -> Int {
        return data.count
    }
    override func rowCount(_ section: Int) -> Int {
        return data[section].count
    }
    
    override func cellTypeAt(_ indexPath: IndexPath) -> UITableViewCell.Type{
        return data[indexPath.section][indexPath.row][0] as! UITableViewCell.Type
    }
    override func getDataItem(_ indexPath : IndexPath) -> TJTableDataSourceItem{
        var a : TableDataSourceItem = [:]
        a["title"] = NSLocalizedString(data[indexPath.section][indexPath.row][1] as! String)
        a["icon"] = data[indexPath.section][indexPath.row][2]
        return a
    }
}
fileprivate class Table : TJTable{
    
    static var shared_ : Table!
    static var shared : Table{
        get{
            if shared_ == nil{
                shared_ = Table()
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
        self.tableData = LeftTableData()
        for item in (tableData as! LeftTableData).data{
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
    
    override func rowHeight(_ indexPath: IndexPath) -> CGFloat {
        if (indexPath.section == 1 && indexPath.row == 2){
            return 55+10
        }
        return [180,55+SEPARATOR_HEIGHT,55+SEPARATOR_HEIGHT][indexPath.section]
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
        Msg.observe(self, #selector(userNameChanged), "UserNameChanged")
    }
    func userNameChanged(){
        avatarImageView.userChanged()
        userNameLabel.text = "请先登录"
        if let user = User.shared.user {
            userNameLabel.text = user.username
        }
    }
}
fileprivate class NodeCell:LeftNodeTableViewCell{
    override func action(_ indexPath : IndexPath){
        Msg.send("pushNodesViewController")
        Msg.send("closeDrawer")
    }
}
fileprivate class MoreCell:LeftNodeTableViewCell{
    override func action(_ indexPath : IndexPath){
        Msg.send("pushMoreViewController")
        Msg.send("closeDrawer")
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
}
fileprivate class LeftNodeTableViewCell: TJCell {
    var _icon = UIImageView()
    var _title = SizeLabel(16)
    
    fileprivate override func load(_ data : PCTableDataSource,_ item : TableDataSourceItem,_ indexPath : IndexPath){
        _title.text = item["title"] as? String
        _icon.image = UIImage.templatedIcon(item["icon"] as! String)
    }
    override func setup(){
        self.selectionStyle = .none
        self.backgroundColor = UIColor.clear
        let views = ["icon":_icon,"title":_title] as [String : UIView]
        layout(contentView,views,["H:|-20-[icon(25)]-20-[title]","V:|-(<=1)-[icon(25)]","V:|-(<=1)-[title(25)]"],[.None,.Y,.Y])
        configureColor()
    }
    func configureColor(){
        self.backgroundColor = V2EXColor.colors.v2_LeftNodeBackgroundColor
        self._icon.tintColor =  V2EXColor.colors.v2_LeftNodeTintColor
        self._title.textColor = V2EXColor.colors.v2_LeftNodeTintColor
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
        _icon.image = UIImage.templatedIcon("ic_notifications_none")
        self._title.text = NSLocalizedString("notifications")
        layout(contentView,["label":notifictionCountLabel,"title":_title],["H:[title]-5-[label]","V:|-(<=1)-[label(14)]"],[.None,.Y])
        Msg.observe(self, #selector(doNotify), "notificationCount")
    }
    func doNotify(){
        if User.shared.notificationCount > 0 {
            self.notifictionCountLabel.text = "   \(User.shared.notificationCount)   "
        }
        else{
            self.notifictionCountLabel.text = ""
        }
    }
}
