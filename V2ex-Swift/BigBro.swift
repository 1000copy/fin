class BigBrotherWatchingYou : UIResponder{
    var centerNavigation :V2EXNavigationController!
    var drawerController : DrawerController!
    var centerViewController : HomeViewController!
    init(_ drawer :  Drawer) {
        super.init()
        self.centerNavigation = drawer.centerNav
        self.drawerController = drawer
        self.centerViewController = drawer.home
        let a : [String:Selector] = [
            "openTopicDetail1":#selector(openTopicDetail1),
            "openTopicDetail":#selector(openTopicDetail),
            "openLeftDrawer":#selector(openLeftDrawer),
            "openRightDrawer":#selector(openRightDrawer),
            "closeDrawer":#selector(closeDrawer),
            "openNodeTopicList":#selector(openNodeTopicList),
            "relevantComment":#selector(relevantComment),
            "replyComment":#selector(replyComment),
            "replyTopic":#selector(replyTopic),
            "openAccountsManager":#selector(openAccountsManager),
            "PanningGestureDisable":#selector(PanningGestureDisable),
            "PanningGestureEnable":#selector(PanningGestureEnable),
            "ChangeTab":#selector(ChangeTab),
            "presentTwoFAViewController":#selector(presentTwoFAViewController),
            "pushMemberViewController":#selector(pushMemberViewController),
            "presentLoginViewController":#selector(presentLoginViewController),
            "pushNotificationsViewController":#selector(pushNotificationsViewController),
            "pushFavoritesViewController":#selector(pushFavoritesViewController),
            "pushNodesViewController":#selector(pushNodesViewController),
            "pushMoreViewController":#selector(pushMoreViewController),
            "pushMyCenterViewController":#selector(pushMyCenterViewController),
            //            "pushSettingsTableViewController":#selectopushSettingsTableViewControllerer),
            "pushPodsTableViewController":#selector(pushPodsTableViewController),
            //            "presentV2PhotoBrowser":#selector(presentV2PhotoBrowser),
            "pushV2WebViewViewController":#selector(pushV2WebViewViewController),
            "presentPhotoBrower":#selector(presentPhotoBrower),
            ]
        for (key, value) in  a {
            //            NotificationCenter.default.addObserver(self, selector: value, name: Notification.Name(key), object: nil)
            Msg.observe(self, value, key)
        }
    }
    func presentPhotoBrower(_ obj : NSNotification){
        let arr = obj.object as! NSArray
        let url = arr[0] as! String
        var images = [SKPhoto]()
        let photo = SKPhoto.photoWithImageURL(url)// add some UIImage
        images.append(photo)
        let browser = SKPhotoBrowser(photos: images)
        browser.initializePageIndex(0)
        self.centerNavigation.pushViewController(browser, animated: true)
    }
    func pushV2WebViewViewController(_ obj : NSNotification){
        let arr = obj.object as! NSArray
        let url = arr[0] as! String
        let controller = V2WebViewViewController(url: url)
        self.centerNavigation.pushViewController(controller, animated: true)
    }
    func pushPodsTableViewController(_ obj : NSNotification){
        centerNavigation?.pushViewController(PodsTableViewController(), animated: true)
    }
    func pushNotificationsViewController(_ obj : NSNotification){
        let notificationsViewController = NotificationsViewController()
        centerNavigation?.pushViewController(notificationsViewController, animated: true)
    }
    func pushFavoritesViewController(_ obj : NSNotification){
        let favoritesViewController = FavoritesViewController()
        centerNavigation?.pushViewController(favoritesViewController, animated: true)
    }
    func pushNodesViewController(_ obj : NSNotification){
        let nodesViewController = NodesViewController()
        centerNavigation?.pushViewController(nodesViewController, animated: true)
    }
    func pushMoreViewController(_ obj : NSNotification){
        let moreViewController = MoreViewController()
        centerNavigation?.pushViewController(moreViewController, animated: true)
    }
    func pushMyCenterViewController(_ obj : NSNotification){
        let arr = obj.object as! NSArray
        let username = arr[0] as! String
        let memberViewController = MyCenterViewController()
        memberViewController.username = username
        centerNavigation?.pushViewController(memberViewController, animated: true)
        Msg.send("closeDrawer")
    }
    func presentLoginViewController(_ obj : NSNotification){
        let loginViewController = LoginViewController()
        centerNavigation?.present(loginViewController, animated: true, completion: nil);
    }
    func pushMemberViewController(_ obj : NSNotification){
        let arr = obj.object as! NSArray
        let username = arr[0] as! String
        let memberViewController = MemberViewController()
        memberViewController.username = username
        centerNavigation?.pushViewController(memberViewController, animated: true)
    }
    func presentTwoFAViewController(_ obj : NSNotification){
        let twoFaViewController = TwoFAViewController()
        centerNavigation?.present(twoFaViewController, animated: true, completion: nil);
    }
    func ChangeTab(_ obj : NSNotification){
        let arr = obj.object as! NSArray
        let nodeTab = arr[0] as! String
        centerViewController.tab = nodeTab
        centerViewController.refreshPage()
    }
    func closeDrawer(_ obj : NSNotification){
        drawerController?.closeDrawer(animated: true, completion: nil)
    }
    func openTopicDetail(_ obj : NSNotification){
        print(obj)
        let arr = obj.object as! NSArray
        let id = arr[0] as! String
        let c = arr[1] as! ((String) -> Void)
        let topicDetailController = TopicDetailViewController();
        topicDetailController.topicId = id ;
        topicDetailController.ignoreTopicHandler = c
        self.centerNavigation?.pushViewController(topicDetailController, animated: true)
    }
    func openTopicDetail1(_ obj : NSNotification){
        let arr = obj.object as! NSArray
        let id = arr[0] as! String
        let topicDetailController = TopicDetailViewController();
        topicDetailController.topicId = id ;
        self.centerNavigation?.pushViewController(topicDetailController, animated: true)
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
        self.centerNavigation?.pushViewController(controller, animated: true)
    }
    func openAccountsManager(_ obj : NSNotification){
        self.centerNavigation?.pushViewController(AccountsManagerViewController(), animated: true)
    }
    func relevantComment(_ obj : NSNotification){
        //UIViewController ,UIViewController, [TopicCommentModel]
        let arr = obj.object as! NSArray
        //        let v1 = arr[0] as! UIViewController
        let tc = arr[1] as! [TopicCommentModel]
        let v2 = RelevantCommentsViewController()
        v2.commentsArray = tc
        //        v1.present(v2, animated: true, completion: nil)
        self.centerNavigation.pushViewController(v2, animated: true)
    }
    func replyTopic(_ obj : NSNotification){
        let arr = obj.object as! NSArray
        let model = arr[0] as! TopicDetailModel
        let n = arr[1] as! UINavigationController
        User.shared.ensureLoginWithHandler {
            let replyViewController = ReplyingViewController()
            replyViewController.topicModel = model
            let nav = V2EXNavigationController(rootViewController:replyViewController)
            n.present(nav, animated: true, completion:nil)
        }
    }
    func openLeftDrawer(_ obj : NSNotification){
        drawerController?.toggleLeftDrawerSide(animated: true, completion: nil)
    }
    func openRightDrawer(_ obj : NSNotification){
        drawerController?.toggleRightDrawerSide(animated: true, completion: nil)
    }
    func PanningGestureDisable(_ obj : NSNotification){
        drawerController?.openDrawerGestureModeMask = []
    }
    func PanningGestureEnable(_ obj : NSNotification){
        drawerController?.openDrawerGestureModeMask = .panningCenterView
    }
}
import SKPhotoBrowser
import UIKit
import Fabric

import DrawerController
import SVProgressHUD
