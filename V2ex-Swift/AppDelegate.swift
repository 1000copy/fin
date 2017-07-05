import UIKit
import Fabric
import Crashlytics
import DrawerController
import SVProgressHUD
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var  star : BigBrotherWatchingYou!
    var window: UIWindow?
    var centerNav : V2EXNavigationController!
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        URLProtocol.registerClass(WebViewImageProtocol.self)
        self.window = UIWindow();
        self.window?.frame=UIScreen.main.bounds;
        self.window?.makeKeyAndVisible();

        centerNav = V2EXNavigationController(rootViewController: HomeViewController());
         star = BigBrotherWatchingYou(centerNav)
        let leftViewController = LeftViewController();
        let rightViewController = RightViewController();
        let drawerController = DrawerController(centerViewController: centerNav!, leftDrawerViewController: leftViewController, rightDrawerViewController: rightViewController);
        
        self.window?.thmemChangedHandler = {[weak self] (style) -> Void in
            self?.window?.backgroundColor = V2EXColor.colors.v2_backgroundColor;
            drawerController.view.backgroundColor = V2EXColor.colors.v2_backgroundColor
        }
        drawerController.maximumLeftDrawerWidth=230;
        drawerController.maximumRightDrawerWidth = rightViewController.maximumRightDrawerWidth()
        drawerController.openDrawerGestureModeMask=OpenDrawerGestureMode.panningCenterView
        drawerController.closeDrawerGestureModeMask=CloseDrawerGestureMode.all;
        self.window?.rootViewController = drawerController;
        V2Client.sharedInstance.drawerController = drawerController
        V2Client.sharedInstance.centerViewController = centerNav?.viewControllers[0] as? HomeViewController
        V2Client.sharedInstance.centerNavigation = centerNav
        #if DEBUG
            let fpsLabel = V2FPSLabel(frame: CGRect(x: 15, y: SCREEN_HEIGHT-40,width: 55,height: 20));
            self.window?.addSubview(fpsLabel);
        #else
        #endif
        
        SVProgressHUD.setForegroundColor(UIColor(white: 1, alpha: 1))
        SVProgressHUD.setBackgroundColor(UIColor(white: 0.15, alpha: 0.85))
        SVProgressHUD.setDefaultMaskType(.none)
        
        /**
        DEBUG 模式下不统计任何信息，如果你需要使用Crashlytics ，请自行申请账号替换我的Key
        */
        #if DEBUG
        #else
            Fabric.with([Crashlytics.self])
        #endif

        return true
    }
}
class BigBrotherWatchingYou : UIResponder{
    var centerNav :V2EXNavigationController!
    init(_ centerNav :V2EXNavigationController) {
        super.init()
        self.centerNav = centerNav
        let a : [String:Selector] = [
            "openTopicDetail1":#selector(openTopicDetail1),
            "openTopicDetail":#selector(openTopicDetail),
            "openLeftDrawer":#selector(openLeftDrawer),
            "openRightDrawer":#selector(openRightDrawer),
            "openNodeTopicList":#selector(openNodeTopicList),
            "relevantComment":#selector(relevantComment),
            "replyComment":#selector(replyComment),
            "replyTopic":#selector(replyTopic),
            "openAccountsManager":#selector(openAccountsManager)
        ]
        for (key, value) in  a {
            NotificationCenter.default.addObserver(self, selector: value, name: Notification.Name(key), object: nil)
        }
    }
    func openTopicDetail(_ obj : NSNotification){
        print(obj)
        let arr = obj.object as! NSArray
        let id = arr[0] as! String
        let c = arr[1] as! ((String) -> Void)
        let topicDetailController = TopicDetailViewController();
        topicDetailController.topicId = id ;
        topicDetailController.ignoreTopicHandler = c
        self.centerNav?.pushViewController(topicDetailController, animated: true)
    }
    func openTopicDetail1(_ obj : NSNotification){
        let arr = obj.object as! NSArray
        let id = arr[0] as! String
        let topicDetailController = TopicDetailViewController();
        topicDetailController.topicId = id ;
        self.centerNav?.pushViewController(topicDetailController, animated: true)
    }
    func replyComment(_ obj : NSNotification) {
        let arr = obj.object as! NSArray
        // viewControler,username ,model
        let viewControler = arr[0] as! UIViewController
        let username = arr[1] as! String
        let model = arr[2] as! TopicDetailModel
        let replyViewController = ReplyingViewController()
        replyViewController.atSomeone = "@" + username + " "
        replyViewController.topicModel = model
        let nav = V2EXNavigationController(rootViewController:replyViewController)
        viewControler.navigationController?.present(nav, animated: true, completion:nil)
    }
    func openNodeTopicList(_ obj : NSNotification){
        let node = NodeModel()
        let arr = obj.object as! NSArray
        node.nodeId = arr[0] as? String
        node.nodeName = arr[1] as? String
        let controller = NodeTopicListViewController()
        controller.node = node
        self.centerNav?.pushViewController(controller, animated: true)
    }
    func openAccountsManager(_ obj : NSNotification){
        self.centerNav?.pushViewController(AccountsManagerViewController(), animated: true)
    }
    func relevantComment(_ obj : NSNotification){
        //UIViewController ,UIViewController, [TopicCommentModel]
        let arr = obj.object as! NSArray
        let v1 = arr[0] as! UIViewController
        let tc = arr[1] as! [TopicCommentModel]
        let v2 = RelevantCommentsNav(comments: tc)
        v1.present(v2, animated: true, completion: nil)
    }
    func replyTopic(_ obj : NSNotification){
        let arr = obj.object as! NSArray
        let model = arr[0] as! TopicDetailModel
        let n = arr[1] as! UINavigationController
        V2User.sharedInstance.ensureLoginWithHandler {
            let replyViewController = ReplyingViewController()
            replyViewController.topicModel = model
            let nav = V2EXNavigationController(rootViewController:replyViewController)
            n.present(nav, animated: true, completion:nil)
        }
    }
    func openLeftDrawer(_ obj : NSNotification){
        V2Client.sharedInstance.drawerController?.toggleLeftDrawerSide(animated: true, completion: nil)
    }
    func openRightDrawer(_ obj : NSNotification){
        V2Client.sharedInstance.drawerController?.toggleRightDrawerSide(animated: true, completion: nil)
    }
}
