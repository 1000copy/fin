import UIKit
fileprivate class Table1 : TableBase{
    fileprivate var users:[LoginUser] = []
    var owner : UIViewController!
    override func rowCount(_ section: Int) -> Int {
        //     账户数量            分割线   退出登录按钮
        return self.users.count   + 1       + 1
    }
    override func rowHeight(_ indexPath: IndexPath) -> CGFloat {
        if indexPath.row < self.users.count {
            return 55
        }
        else if indexPath.row == self.users.count {//分割线
            return 15
        }
        else { //退出登录按钮
            return 45
        }
    }
    override func cellAt(_ indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < self.users.count {
            let cell = getCell(self, cell: AccountListTableViewCell.self, indexPath: indexPath)
            cell.bind(self.users[indexPath.row])
            return cell
        }
        else if indexPath.row == self.users.count {//分割线
            let cell = UITableViewCell()
            cell.backgroundColor = self.backgroundColor
            return cell
        }
        else{
            return getCell(self, cell: LogoutTableViewCell.self, indexPath: indexPath)
        }
    }
    override func canEditRowAt(_ indexPath: IndexPath) -> Bool {
        return indexPath.row < self.users.count
    }
    override func commitDelete(_ indexPath: IndexPath){
        if let username = self.users[indexPath.row].username {
            self.users.remove(at: indexPath.row)
            UserListKeychain.shared.removeUser(username)
            deleteRows(at: [indexPath], with: .none)
        }
    }
    override func didSelectRowAt(_ indexPath: IndexPath) {
        self.deselectRow(at: indexPath, animated: true)
        let totalNumOfRows = self.tableView(self, numberOfRowsInSection: 0)
        if indexPath.row < self.users.count {
            let user = self.users[indexPath.row]
            if user.username == User.shared.username {
                return;
            }
            alertView = AlertToggleUser(ownerViewController,indexPath.row)
            alertView.done  = alertView2
            alertView.show(user.username!, indexPath)
        }
        //最后一行，也就是退出登录按钮那行
        else if indexPath.row == totalNumOfRows - 1{
            alert = AlertLogout(ownerViewController)
            alert.done = alertView1
            alert.show()
        }
    }
    // alert view
    var alertView : AlertToggleUser!
    var alert : AlertLogout!
    func alertView1(_ buttonIndex: Int){
        if buttonIndex == 1 {
            User.shared.loginOut()
            let _ = self.ownerViewController?.navigationController?.popToRootViewController(animated: true)
        }
        
    }
    func alertView2(_ buttonIndex: Int){
        if buttonIndex == 0 {
            return
        }
        User.shared.loginOut()
        self.reloadData()
        let user = self.users[alertView.row]
        if let username = user.username,let password = user.password {
            V2BeginLoadingWithStatus("正在登录")
            UserModel.Login(username, password: password){
                (response:V2ValueResponse<String> , is2FALoggedIn:Bool) -> Void in
                if response.success {
                    V2Success("登录成功")
                    let username = response.value!
                    NSLog("登录成功 %@",username)
                    //保存下用户名
                    Setting.shared.kUserName = username
                    //获取用户信息
                    UserModel.getUserInfoByUsername(username, completionHandler: { (response) -> Void in
                        self.reloadData()
                    })
                    if is2FALoggedIn {
                        Msg.send("presentTwoFAViewController", [])
                    }
                }
                else{
                    V2Error(response.message)
                }
            }
        }
    }
}
class AccountsManagerViewController: UIViewController {
    fileprivate var _tableView :Table1!
    fileprivate var tableView: Table1{
        get{
            if(_tableView != nil){
                return _tableView!;
            }
            _tableView = Table1();
            _tableView.backgroundColor = V2EXColor.colors.v2_backgroundColor
            _tableView.estimatedRowHeight=100;
            _tableView.separatorStyle = UITableViewCellSeparatorStyle.none;
            regClass(_tableView, cell: AccountListTableViewCell.self);
            regClass(_tableView, cell: LogoutTableViewCell.self)
            _tableView.delegate = _tableView;
            _tableView.dataSource = _tableView;
            _tableView.owner = self
            
            return _tableView!;
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("accounts")
        self.view.backgroundColor = V2EXColor.colors.v2_backgroundColor

        let warningButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        warningButton.contentMode = .center
        warningButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -20)
        warningButton.setImage(UIImage.imageUsedTemplateMode("ic_warning")!.withRenderingMode(.alwaysTemplate), for: UIControlState())
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: warningButton)
        warningButton.addTarget(self, action: #selector(AccountsManagerViewController.warningClick), for: .touchUpInside)

        self.view.addSubview(self.tableView);
        self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0)
        self.tableView.snp.makeConstraints{ (make) -> Void in
            make.top.bottom.equalTo(self.view);
            make.center.equalTo(self.view);
            make.width.equalTo(SCREEN_WIDTH)
        }

        for (_,user) in UserListKeychain.shared.users {
            self._tableView.users.append(user)
        }
    }
    func warningClick(){
         AlertPrivateDeclare(ownerViewController).show()
    }
}

class AlertLogout : AlertBase{
    override func show(){
        title = "确定注销当前账号吗？"
        message =  "注销会退出登录"
        otherTitle = "注销"
        super.show()
    }
}
class AlertToggleUser : AlertBase{
    var row : Int = 0
    init(_ owner : UIViewController?,_ row : Int) {
        super.init(owner)
        self.row = row
    }
    func show(_ username : String,_ indexPath : IndexPath){
        title = "确定切换到账号 " + username + " 吗?"
        message =  "无论新账号是否登录成功，都会注销当前账号。"
        otherTitle = "确定"
        super.show()
    }
}
class AlertPrivateDeclare: AlertBase{
    override func show(){
        title = "推荐"
        message =   "强烈推荐你不要关闭，因为这个会帮助你【登录过期自动重连】、或者【切换多账号】"
        cancelTitle = "我知道了"
        super.show()
    }
}
class AlertBase : NSObject,UIAlertViewDelegate{
    var owner : UIViewController?
    var done : ((_ buttonIndex: Int)->Void)?
    var buttonTap : ((_ title: String?)->Void)?
    var title : String!=""
    var message : String!=""
    var cancelTitle : String!="取消"
    var otherTitle : String!="其他"
    var alertView : UIAlertController!
    init(_ owner : UIViewController?) {
        self.owner = owner
    }
    func show() {
        alertView = UIAlertController(title:self.title, message:self.message, preferredStyle:UIAlertControllerStyle.alert)
        var action = UIAlertAction(title:cancelTitle, style:UIAlertActionStyle.default){[weak self] action in
            self?.buttonTap?((self?.cancelTitle)!)
            self?.done?(0)
        }
        alertView.addAction(action)
        action = UIAlertAction(title:otherTitle, style:UIAlertActionStyle.default){[weak self] action in
            self?.buttonTap?((self?.cancelTitle)!)
            self?.done?(1)
        }
        alertView.addAction(action)
        owner?.present(alertView, animated:true, completion:nil)
    }
}
