typealias TJCollectionView = CollectionViewBase
typealias TJCell = CellBase
typealias TJTable = DataTableBase
typealias TJTableDataSource = TableDataSource
typealias TJTableDataSourceItem = TableDataSourceItem
typealias TJButton = ButtonBase

typealias Callback =  (()-> Void)
typealias CallbackMore =  ((_ moreData : Bool)-> Void)

class CollectionViewBase : UICollectionView,UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout{
    func sectionCount() -> Int {
        return 0
    }
    func itemCount(_ section: Int) -> Int {
        return 0
    }
    func cellAt(_ indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
    func viewFor(_ kind: String, _ indexPath: IndexPath) -> UICollectionReusableView {
        return UICollectionReusableView()
    }
    func didSelectItemAt(_ indexPath: IndexPath){
    }
    func sizeFor(_ collectionViewLayout: UICollectionViewLayout, _ indexPath: IndexPath) -> CGSize {
        return CGSize(width: 0, height: 0);
    }
    func minimumInteritemSpacingForSectionAt(_ collectionViewLayout: UICollectionViewLayout, section: Int) -> CGFloat{
        return 0.0
    }
    func referenceSizeForHeaderIn(_  collectionViewLayout: UICollectionViewLayout, _ section: Int) -> CGSize{
        return CGSize(width: self.bounds.size.width, height: 35);
    }
    
    // implements
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        dataSource = self
        delegate = self
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func registerCell(_ cellClass: Swift.AnyClass?){
        let id = "\(cellClass)"
        register(cellClass, forCellWithReuseIdentifier: id)
    }
    func dequeueCell(_ cellClass: Swift.AnyClass?,_ indexPath: IndexPath)-> UICollectionViewCell{
        let id = "\(cellClass)"
        return dequeueReusableCell(withReuseIdentifier: id, for: indexPath)
    }
    func registerHeaderView(_ cellClass: Swift.AnyClass?){
        let id = "\(cellClass)"
        register(cellClass, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: id)
    }
    func dequeueHeaderView(_ cellClass: Swift.AnyClass?,_ indexPath: IndexPath)-> UICollectionReusableView{
        let id = "\(cellClass)"
        return dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: id, for: indexPath)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        didSelectItemAt(indexPath)
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sectionCount()
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemCount(section)
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return cellAt(indexPath)
    }
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return viewFor(kind, indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return sizeFor(collectionViewLayout,indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat{
        return minimumInteritemSpacingForSectionAt(collectionViewLayout, section: section)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
        return referenceSizeForHeaderIn(collectionViewLayout, section)
    }
}
class ImageBase : UIImageView{
    func kfImage(_ url : String,_ cb : @escaping Callback){
        kf.setImage(with: URL(string: url)!, placeholder: nil, options: nil){
            (image, error, cacheType, imageURL) -> () in
            cb()
        }
    }
}
class Msg {
    class func send( _ name : String, _ object : Any?){
        NotificationCenter.default.post(name: Notification.Name(name), object: object)
    }
    class func send( _ name : String){
        send(name,nil)
    }
    class func observe(_ owner : NSObject , _ responser : Selector , _ msg : String, _ object : Any?){
        NotificationCenter.default.addObserver(owner, selector: responser, name: Notification.Name(msg), object: nil)
    }
    class func observe(_ owner : NSObject , _ responser : Selector , _ msg : String){
        observe(owner, responser, msg,nil)
    }
    class func observe(_ owner : NSObject , _ responser : Selector , _ msg : Notification.Name){
        NotificationCenter.default.addObserver(owner, selector: responser, name: msg, object: nil)
    }
}
enum CenterOption {
    case X
    case Y
    case None
}

func layout(_ superview : UIView,_ views : [String:UIView],_ contraints : [String],_ options:[CenterOption]){
    for view in views{
        view.value.translatesAutoresizingMaskIntoConstraints = false
        if  !view.value.isDescendant(of: superview){
            superview.addSubview(view.value)
        }
    }
    
    var i = 0
    for contraint in contraints{
        var option = NSLayoutFormatOptions.init(rawValue: 0)
        if options[i] == .Y {
            option = .alignAllCenterY
        }else if options[i] == .X {
            option = .alignAllCenterX
        }
        superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat:contraint , options: option, metrics: nil, views: views))
        i += 1
    }
}
class ButtonBase : UIButton{
    var touchUp_ : Callback?
    var tap : Callback?{
        get{
            return touchUp_
        }
        set{
            touchUp_ = newValue
        }
    }
    func doTouchUp(){
        if let t = tap {
            t()
        }
    }
    func onLoad(){
        
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addTarget(self, action: #selector(doTouchUp), for: .touchUpInside)
        onLoad()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var icon : String?{
        didSet {
            let icon_ = icon
            if icon_ != nil && icon_ != ""{
                let image = UIImage.imageUsedTemplateMode(icon_!)!
                setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
            }
        }
    }
}

class TJLabel : UILabel{
    override init(frame: CGRect) {
        super.init(frame:CGRect.zero)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func tap(_ sender:UITapGestureRecognizer) {
        tap?()
    }
    var tapped_ : Callback?
    var tap : Callback?{
        get {
            return tapped_
        }
        set{
            tapped_ = newValue
            if tapped_ != nil {
                isUserInteractionEnabled = true
                addGestureRecognizer( UITapGestureRecognizer(target: self, action: #selector(tap(_:))))
            }
        }
    }
}

class SizeLabel : TJLabel{
    init(_ fontSize : CGFloat){
        super.init(frame: CGRect.zero)
        font = v2Font(fontSize)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
class LinesLabel : SizeLabel{
    override init(_ fontSize : CGFloat){
        super.init(fontSize)
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
class Avatar : TJImage{
//    init(_ size : CGFloat){
//        super.init("")
//        contentMode = .scaleAspectFit
//        frame.size.height = size
//        frame.size.width = size
//    }
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
}
func TJRect (_ x : CGFloat,_ y : CGFloat,_ width : CGFloat,_ height : CGFloat)-> CGRect{
    return CGRect(x: x, y: y, width: width, height: height)
}
func TJSquare (_ x : CGFloat,_ y : CGFloat,_ size : CGFloat)-> CGRect{
    return CGRect(x: x, y: y, width: size, height: size)
}
class TJPage : UIViewController{
    // interface
    func onLoad (){
        
    }
    func onShow (){
        
    }
    func onHide (){
        
    }
    func onAppRise (){
        
    }
    func onAppFall (){
        
    }
    func onLayout(){
        
    }
    func getNavItems ()->[UIButton]{
        return []
    }
    func getSubviews()->[UIView]?{
        return []
    }
    // imple
    override func viewDidLoad() {
        super.viewDidLoad()
        Msg.observe(self, #selector(applicationWillEnterForeground), NSNotification.Name.UIApplicationWillEnterForeground)
        Msg.observe(self, #selector(applicationDidEnterBackground), NSNotification.Name.UIApplicationDidEnterBackground)
        setupNavigationItem()
        if let views = getSubviews() , views.count > 0 {
            for view in views{
                self.view.addSubview(view)
            }
        }
        onLoad()
        onLayout()
    }
    
    func applicationWillEnterForeground(){
        onAppRise()
    }
    func applicationDidEnterBackground(){
        onAppFall()
    }
    override func viewWillAppear(_ animated: Bool) {
        onShow()
    }
    override func viewWillDisappear(_ animated: Bool) {
        onHide()
    }
    
    func setupNavigationItem(){
        let buttons = getNavItems()
        if buttons.count  >=  1   {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: buttons[0])
        }
        if buttons.count  >=  2   {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: buttons[1])
        }
    }
}
class SecondTimer {
    var second : Double?
    init(_ second : Double){
        self.second = second
    }
    var lastLeaveTime = Date()
    func begin(){
        lastLeaveTime = Date()
    }
    var  isArrived : Bool{
        get {
            return (-1 * lastLeaveTime.timeIntervalSinceNow) > second!
        }
    }
}
class TJImage :UIImageView{
    func onLoad(){
        
    }
    var owner : UIView!
    convenience init() {
        self.init(nil)
    }
    init(_ owner : UIView?) {
        super.init(frame: CGRect.zero)
        self.owner = owner
        onLoad()
    }
    var icon : String?{
        didSet{
            if let icon = icon {
                image = UIImage(named: icon)
            }
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func tap(_ sender:UITapGestureRecognizer) {
        tap?()
    }
    var tapped_ : Callback?
    var tap : Callback?{
        get {
            return tapped_
        }
        set{
            tapped_ = newValue
            if tapped_ != nil {
                isUserInteractionEnabled = true
                addGestureRecognizer( UITapGestureRecognizer(target: self, action: #selector(tap(_:))))
            }
        }
    }
}

class TJBlur : FXBlurView{
    var owner : UIView?
    func onLoad(){
        
    }
    init(_ owner : UIView) {
        self.owner = owner
        super.init(frame: CGRect.zero)
        onLoad()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
class TJView :UIView{
    func onLoad(){
        
    }
    var owner : UIView!
    convenience init() {
        self.init(nil)
    }
    init(_ owner : UIView?) {
        super.init(frame: CGRect.zero)
        self.owner = owner
        onLoad()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func tap(_ sender:UITapGestureRecognizer) {
        tap?()
    }
    var tapped_ : Callback?
    var tap : Callback?{
        get {
            return tapped_
        }
        set{
            tapped_ = newValue
            if tapped_ != nil {
                isUserInteractionEnabled = true
                addGestureRecognizer( UITapGestureRecognizer(target: self, action: #selector(tap(_:))))
            }
        }
    }
    var longPress :((_ sender:UILongPressGestureRecognizer) -> Void)?{
        didSet{
            if longPress != nil {
                isUserInteractionEnabled = true
                let e = UILongPressGestureRecognizer(target: self,
                                             action: #selector(longPressHandle(_:))
                )
                addGestureRecognizer(e)
            }
        }
    }
    func longPressHandle(_ sender:UILongPressGestureRecognizer){
      longPress?(sender)
    }
}
class TJApp: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        onLoad()
        return true
    }
    func onLoad(){
        
    }
}
class TJWin : UIWindow{
    init(_ rootvc : UIViewController) {
        super.init(frame:UIScreen.main.bounds)
        makeKeyAndVisible()
        rootViewController = rootvc
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
class TJDrawer : DrawerController{
    init( _ centerViewController: UIViewController!, _ leftDrawerViewController: UIViewController, _ rightDrawerViewController: UIViewController) {
        super.init(centerViewController: centerViewController, leftDrawerViewController: leftDrawerViewController, rightDrawerViewController: rightDrawerViewController)
        maximumLeftDrawerWidth=230;
        maximumRightDrawerWidth = (rightDrawerViewController as! RightViewController).maxWidth()
        openDrawerGestureModeMask=OpenDrawerGestureMode.panningCenterView
        closeDrawerGestureModeMask=CloseDrawerGestureMode.all
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

import FXBlurView
import UIKit
import SnapKit
import Alamofire
import AlamofireObjectMapper
import Ji
import Foundation
import UIKit
import Fabric

import DrawerController
import SVProgressHUD
