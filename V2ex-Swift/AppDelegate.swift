import UIKit
import Fabric
import Crashlytics

import DrawerController
import SVProgressHUD

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var centerNav : V2EXNavigationController?
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
    func openNodeTopicList(_ obj : NSNotification){
                let node = NodeModel()
                let arr = obj.object as! NSArray
                node.nodeId = arr[0] as? String
                node.nodeName = arr[1] as? String
                let controller = NodeTopicListViewController()
                controller.node = node
                self.centerNav?.pushViewController(controller, animated: true)
    }
    
    func openLeftDrawer(_ obj : NSNotification){
        V2Client.sharedInstance.drawerController?.toggleLeftDrawerSide(animated: true, completion: nil)
    }
    func openRightDrawer(_ obj : NSNotification){
        V2Client.sharedInstance.drawerController?.toggleRightDrawerSide(animated: true, completion: nil)
    }
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        URLProtocol.registerClass(WebViewImageProtocol.self)
        NotificationCenter.default.addObserver(self, selector: #selector(openTopicDetail), name: Notification.Name("open topic detail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openLeftDrawer), name: Notification.Name("openLeftDrawer"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openRightDrawer), name: Notification.Name("openRightDrawer"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openNodeTopicList), name: Notification.Name("openNodeTopicList"), object: nil)
        self.window = UIWindow();
        self.window?.frame=UIScreen.main.bounds;
        self.window?.makeKeyAndVisible();

        centerNav = V2EXNavigationController(rootViewController: HomeViewController());
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
//        self.window?.rootViewController = MemberViewController()

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
