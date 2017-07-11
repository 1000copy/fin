import UIKit
import FXBlurView
import KVOController
import Kingfisher
class LeftViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    var backgroundImageView:UIImageView?
    var frostedView = FXBlurView()
    fileprivate var _tableView :UITableView!
    fileprivate var tableView: UITableView {
        get{
            if(_tableView != nil){
                return _tableView!;
            }
            _tableView = UITableView();
            _tableView.backgroundColor = UIColor.clear
            _tableView.estimatedRowHeight=100;
            _tableView.separatorStyle = UITableViewCellSeparatorStyle.none;
            
            regClass(self.tableView, cell: LeftUserHeadCell.self)
            regClass(self.tableView, cell: LeftNodeTableViewCell.self)
            regClass(self.tableView, cell: LeftNotifictionCell.self)
            
            _tableView.delegate = self;
            _tableView.dataSource = self;
            return _tableView!;
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = V2EXColor.colors.v2_backgroundColor;
        
        self.backgroundImageView = UIImageView()
        self.backgroundImageView!.frame = self.view.frame
        self.backgroundImageView!.contentMode = .scaleToFill
        view.addSubview(self.backgroundImageView!)
        
        frostedView.underlyingView = self.backgroundImageView!
        frostedView.isDynamic = false
        frostedView.tintColor = UIColor.black
        frostedView.frame = self.view.frame
        self.view.addSubview(frostedView)
        
        self.view.addSubview(self.tableView);
        self.tableView.snp.makeConstraints{ (make) -> Void in
            make.top.right.bottom.left.equalTo(self.view);
        }
        
        if User.shared.isLogin {
            self.getUserInfo(User.shared.username!)
        }
        self.thmemChangedHandler = {[weak self] (style) -> Void in
            if V2EXColor.sharedInstance.style == V2EXColor.V2EXColorStyleDefault {
                self?.backgroundImageView?.image = UIImage(named: "32.jpg")
            }
            else{
                self?.backgroundImageView?.image = UIImage(named: "12.jpg")
            }
            self?.frostedView.updateAsynchronously(true, completion: nil)
        }
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return [1,3,2][section]
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.section == 1 && indexPath.row == 2)
        
        {
            return 55+10
        }
        return [180,55+SEPARATOR_HEIGHT,55+SEPARATOR_HEIGHT][indexPath.section]
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if  indexPath.row == 0 {
                let cell = getCell(tableView, cell: LeftUserHeadCell.self, indexPath: indexPath);
                return cell ;
            }
            else {
                return UITableViewCell()
            }
        }
        else if (indexPath.section == 1) {
            if indexPath.row == 1 {
                let cell = getCell(tableView, cell: LeftNotifictionCell.self, indexPath: indexPath)
                cell.nodeImageView.image = UIImage.imageUsedTemplateMode("ic_notifications_none")
                return cell
            }
            else {
                let cell = getCell(tableView, cell: LeftNodeTableViewCell.self, indexPath: indexPath)
                cell.nodeNameLabel.text = [NSLocalizedString("me"),"",NSLocalizedString("favorites")][indexPath.row]
                let names = ["ic_face","","ic_turned_in_not"]
                cell.nodeImageView.image = UIImage.imageUsedTemplateMode(names[indexPath.row])
                return cell
            }
        }
        else {
            let cell = getCell(tableView, cell: LeftNodeTableViewCell.self, indexPath: indexPath)
            cell.nodeNameLabel.text = [NSLocalizedString("nodes"),NSLocalizedString("more")][indexPath.row]
            let names = ["ic_navigation","ic_settings_input_svideo"]
            cell.nodeImageView.image = UIImage.imageUsedTemplateMode(names[indexPath.row])
            return cell
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                if !User.shared.isLogin {
                    Msg.send("presentLoginViewController")
                }else{
                    Msg.send("pushMyCenterViewController",[User.shared.username])
                }
            }
        }
        else if indexPath.section == 1 {
            if !User.shared.isLogin {
                Msg.send("presentLoginViewController")
                return
            }
            if indexPath.row == 0 {
                Msg.send("pushMyCenterViewController",[User.shared.username])
            }
            else if indexPath.row == 1 {
                Msg.send("pushNotificationsViewController")
            }
            else if indexPath.row == 2 {
                Msg.send("pushFavoritesViewController")
            }
            Msg.send("closeDrawer")
            
        }
        else if indexPath.section == 2 {
            if indexPath.row == 0 {
                Msg.send("pushNodesViewController")
            }
            else if indexPath.row == 1 {
                Msg.send("pushMoreViewController")
            }
            Msg.send("closeDrawer")
        }
    }
    
    
    
    // MARK: 获取用户信息
    func getUserInfo(_ userName:String){
        UserModel.getUserInfoByUsername(userName) {(response:V2ValueResponse<UserModel>) -> Void in
            if response.success {
//                self?.tableView.reloadData()
                NSLog("获取用户信息成功")
            }
            else{
                NSLog("获取用户信息失败")
            }
        }
    }

}


fileprivate class LeftUserHeadCell: UITableViewCell {
    /// 头像
    var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor(white: 0.9, alpha: 0.3)
        imageView.layer.borderWidth = 1.5
        imageView.layer.borderColor = UIColor(white: 1, alpha: 0.6).cgColor
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 38
        return imageView
    }()
    /// 用户名
    var userNameLabel: UILabel = {
        let label = UILabel()
        label.font = v2Font(16)
        return label
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
        
        self.avatarImageView.snp.makeConstraints{ (make) -> Void in
            make.centerX.equalTo(self.contentView)
            make.centerY.equalTo(self.contentView).offset(-8)
            make.width.height.equalTo(self.avatarImageView.layer.cornerRadius * 2)
        }
        self.userNameLabel.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(self.avatarImageView.snp.bottom).offset(10)
            make.centerX.equalTo(self.avatarImageView)
        }
        
        self.kvoController.observe(User.shared, keyPath: "username", options: [.initial , .new]){
            [weak self] (observe, observer, change) -> Void in
            if let weakSelf = self {
                if let user = User.shared.user {
                    weakSelf.userNameLabel.text = user.username
                    if let avatar = user.avatar_large {
                        weakSelf.avatarImageView.kf.setImage(with: URL(string: "https:"+avatar)!, placeholder: nil, options: nil, completionHandler: { (image, error, cacheType, imageURL) -> () in
                            //如果请求到图片时，客户端已经不是登录状态了，则将图片清除
                            if !User.shared.isLogin {
                                weakSelf.avatarImageView.image = nil
                            }
                        })
                    }
                }
                else { //没有登录
                    weakSelf.userNameLabel.text = "请先登录"
                    weakSelf.avatarImageView.image = nil
                }
            }
        }
        
        self.thmemChangedHandler = {[weak self] (style) -> Void in
            self?.userNameLabel.textColor = V2EXColor.colors.v2_TopicListUserNameColor
        }
    }
    
}
fileprivate class LeftNodeTableViewCell: UITableViewCell {
    
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
    
    func setup()->Void{
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


fileprivate class LeftNotifictionCell : LeftNodeTableViewCell{
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
