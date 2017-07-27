typealias TJCollectionView = CollectionViewBase
typealias TJCell = CellBase
typealias TJTable = DataTableBase
typealias TJTableDataSource = TableDataSource
typealias TJTableDataSourceItem = TableDataSourceItem
typealias TJButton = ButtonBase
// Button,TableView,CollectView
class DataTableBase : TableBase{
    var tableData_ : PCTableDataSource! = TableDataSource()
    var tableData : PCTableDataSource!{
        get{
            return tableData_
        }
        set{
            tableData_ = newValue
            
        }
    }
    override func sectionCount() -> Int {
        return tableData.sectionCount()
    }
    override func rowCount(_ section: Int) -> Int {
        return tableData.rowCount(section)
    }
    override func rowHeight(_ indexPath: IndexPath) -> CGFloat {
        return tableData.rowHeight(indexPath)
    }
    func getDataItem(_ indexPath : IndexPath) -> TableDataSourceItem{
        return tableData.getDataItem(indexPath)
    }
    var registed : Bool = false
    func registerCells(){
        if !registed {
            registerCells(cellTypes())
            registed = true
        }
    }
    override func cellAt(_ indexPath: IndexPath) -> UITableViewCell {
        let ctype = cellTypeAt(indexPath)
        registerCells()
        let cell = dequeneCell(ctype, indexPath) as! CellBase
        cell.load(tableData,getDataItem(indexPath), indexPath)
        return cell ;
    }
    func cellTypeAt(_ indexPath: IndexPath) -> UITableViewCell.Type{
        if cellTypes().count == 1 {
            return cellTypes()[0]
        }else if tableData != nil{
            return tableData.cellTypeAt!(indexPath)
        }
        return UITableViewCell.self
    }
    func dequeneCell<T:UITableViewCell>(_ indexPath:IndexPath) -> T {
        registerCells()
        return super.dequeneCell(cellTypeAt(indexPath), indexPath) as! T ;
    }
    func cellTypes() ->[UITableViewCell.Type]{
        if tableData != nil{
            return tableData.cellTypes()
        }
        return []
    }
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame:frame,style:style)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
typealias  TableDataSourceItem = [String:Any]
@objc  protocol PCTableDataSource {
    func sectionCount() -> Int
    func rowCount(_ section: Int) -> Int
    func rowHeight(_ indexPath: IndexPath) -> CGFloat
    @objc optional func cellTypeAt(_ indexPath: IndexPath) -> UITableViewCell.Type
    func cellTypes() ->[UITableViewCell.Type]
    func getDataItem(_ indexPath : IndexPath) -> TableDataSourceItem
}
class TableDataSource : NSObject,PCTableDataSource{
    func sectionCount() -> Int {
        return 1
    }
    func rowCount(_ section: Int) -> Int {
        return 0;
    }
    func rowHeight(_ indexPath: IndexPath) -> CGFloat {
        return 48
    }
    func cellTypeAt(_ indexPath: IndexPath) -> UITableViewCell.Type{
        if cellTypes().count == 1 {
            return cellTypes()[0]
        }else{
            return CellBase.self
        }
    }
    func cellTypes() ->[UITableViewCell.Type]{
        return []
    }
    func getDataItem(_ indexPath : IndexPath) -> TableDataSourceItem{
        return [:]
    }
}
class CellBase : UITableViewCell {
    // interface
    func setup(){
    }
    func load(_ data : PCTableDataSource,_ item : TableDataSourceItem,_ indexPath : IndexPath){
        
    }
    func loadCell(_ data : TableDataSourceItem){
        
    }
    
    func action(_ indexPath : IndexPath){
    }
    func onLoad(){
        
    }
    func onLayout(){
        
    }
    // imple
    func deselect(){
        ownerTableView?.deselectRow(at:(ownerTableView?.indexPath(for: self))!,animated: true)
    }
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier);
        self.setup();
        self.onLoad()
        self.onLayout()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
extension UIResponder {
    var ownerViewController : UIViewController? {
        get{
        if self.next is UIViewController {
            return self.next as? UIViewController
        } else {
            if self.next != nil {
                return (self.next!).ownerViewController
            }
            else {return nil}
        }
        }
    }
}
class  TableBase : UITableView, UITableViewDataSource,UITableViewDelegate {
    // 子类接口区
    func rowHeight(_ indexPath: IndexPath) -> CGFloat {
        return 0.0
    }
    func sectionCount() -> Int {
        return 1
    }
    func rowCount(_ section: Int) -> Int {
        return 0
    }
    func cellAt(_ indexPath: IndexPath) -> UITableViewCell{
        return UITableViewCell()
    }
    func didSelectRowAt(_ indexPath: IndexPath) {
        let cell = self.cellForRow(at: indexPath)
        if let p  = cell as? CellBase {
            p.action(indexPath)
        }
    }
    func canEditRowAt(_ indexPath: IndexPath) -> Bool {
        return true
    }
    func commitDelete(_ indexPath: IndexPath){
        
    }
    func commitInsert(_ indexPath: IndexPath){
        
    }
    // 实现区
    func registerCells(_ cells:[AnyClass]){
        for cell in cells {
            self.register( cell, forCellReuseIdentifier: "\(cell)");
        }
    }
    func registerCell(_ cell:AnyClass){
        self.register( cell, forCellReuseIdentifier: "\(cell)");
    }
    func dequeneCell<T: UITableViewCell>(_ cell: T.Type ,_ indexPath:IndexPath) -> T {
        return self.dequeueReusableCell(withIdentifier: "\(cell)", for: indexPath) as! T ;
    }
    var scrollUp : ((_ cb : @escaping Callback)-> Void)?
    var scrollDown : ((_ cb : @escaping CallbackMore)-> Void)?
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            commitDelete(indexPath)
        }else if editingStyle == .insert {
            commitInsert(indexPath)
        }else{
            
        }
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return canEditRowAt(indexPath)
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionCount()
    }
    func beginScrollUp(){
        if mj_footer.isRefreshing() {
            mj_footer.endRefreshing()
        }
        mj_header.beginRefreshing()
    }
    func endScrollUp(){
        mj_header.endRefreshing()
    }
    func endScrollDown(_ hasMoreData : Bool = true){
        if hasMoreData{
            self.mj_footer.endRefreshing()
        }else{
            self.mj_footer.endRefreshingWithNoMoreData()
        }
    }
    func beginRefresh(){
        mj_header.beginRefreshing();
    }
    //    func endRefresh(_ hasMoreData : Bool = true){
    //        if hasMoreData{
    //            self.mj_footer.endRefreshing()
    //        }else{
    //            self.mj_footer.endRefreshingWithNoMoreData()
    //        }
    //    }
    
    func resetNoMoreData(){
        self.mj_footer.resetNoMoreData()
    }
    func onLoad(){
        
    }
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame:frame,style:style)
        self.dataSource = self
        self.delegate = self
        mj_header = V2RefreshHeader(refreshingBlock: {[weak self] () -> Void in
            if let s = self?.scrollUp{
                //如果有上拉加载更多 正在执行，则取消它
                if (self?.mj_footer.isRefreshing())! {
                    self?.mj_footer.endRefreshing()
                }
                s(){
                    self?.mj_header.endRefreshing()
                }
            }
        })
        let footer = V2RefreshFooter(refreshingBlock: {[weak self] () -> Void in
            if let s = self?.scrollDown{
                s(){moreData in
                    self?.mj_header.endRefreshing()
                    if moreData {
                        self?.mj_footer.endRefreshing()
                    }else{
                        self?.mj_footer.endRefreshingWithNoMoreData()
                    }
                }
                
            }
        })
        footer?.centerOffset = -4
        mj_footer = footer
        onLoad()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowCount(section)
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight(indexPath)
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cellAt(indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectRowAt(indexPath)
    }
}

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
fileprivate  class V2RefreshHeader: MJRefreshHeader {
    var loadingView:UIActivityIndicatorView?
    var arrowImage:UIImageView?
    
    override var state:MJRefreshState{
        didSet{
            switch state {
            case .idle:
                self.loadingView?.isHidden = true
                self.arrowImage?.isHidden = false
                self.loadingView?.stopAnimating()
            case .pulling:
                self.loadingView?.isHidden = false
                self.arrowImage?.isHidden = true
                self.loadingView?.startAnimating()
                
            case .refreshing:
                self.loadingView?.isHidden = false
                self.arrowImage?.isHidden = true
                self.loadingView?.startAnimating()
            default:
                NSLog("")
            }
        }
    }
    
    /**
     初始化工作
     */
    override func prepare() {
        super.prepare()
        self.mj_h = 50
        
        self.loadingView = UIActivityIndicatorView(activityIndicatorStyle: .white)
        self.addSubview(self.loadingView!)
        
        self.arrowImage = UIImageView(image: UIImage.imageUsedTemplateMode("ic_arrow_downward"))
        self.addSubview(self.arrowImage!)
        
//        self.thmemChangedHandler = {[weak self] (style) -> Void in
            if V2EXColor.sharedInstance.style == V2EXColor.V2EXColorStyleDefault {
                self.loadingView?.activityIndicatorViewStyle = .gray
                self.arrowImage?.tintColor = UIColor.gray
            }
            else{
                self.loadingView?.activityIndicatorViewStyle = .white
                self.arrowImage?.tintColor = UIColor.gray
            }
//        }
    }
    
    /**
     在这里设置子控件的位置和尺寸
     */
    override func placeSubviews(){
        super.placeSubviews()
        self.loadingView!.center = CGPoint(x: self.mj_w/2, y: self.mj_h/2);
        self.arrowImage!.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        self.arrowImage!.center = self.loadingView!.center
    }
    
    override func scrollViewContentOffsetDidChange(_ change: [AnyHashable: Any]!) {
        super.scrollViewContentOffsetDidChange(change)
    }
    
    override func scrollViewContentSizeDidChange(_ change: [AnyHashable: Any]!) {
        super.scrollViewContentOffsetDidChange(change)
    }
    
    override func scrollViewPanStateDidChange(_ change: [AnyHashable: Any]!) {
        super.scrollViewPanStateDidChange(change)
    }
    
}
fileprivate class V2RefreshFooter: MJRefreshAutoFooter {
    
    var loadingView:UIActivityIndicatorView?
    var stateLabel:UILabel?
    
    var centerOffset:CGFloat = 0
    
    fileprivate var _noMoreDataStateString:String?
    var noMoreDataStateString:String? {
        get{
            return self._noMoreDataStateString
        }
        set{
            self._noMoreDataStateString = newValue
            self.stateLabel?.text = newValue
        }
    }
    
    override var state:MJRefreshState{
        didSet{
            switch state {
            case .idle:
                self.stateLabel?.text = nil
                self.loadingView?.isHidden = true
                self.loadingView?.stopAnimating()
            case .refreshing:
                self.stateLabel?.text = nil
                self.loadingView?.isHidden = false
                self.loadingView?.startAnimating()
            case .noMoreData:
                self.stateLabel?.text = self.noMoreDataStateString
                self.loadingView?.isHidden = true
                self.loadingView?.stopAnimating()
            default:break
            }
        }
    }
    
    /**
     初始化工作
     */
    override func prepare() {
        super.prepare()
        self.mj_h = 50
        
        self.loadingView = UIActivityIndicatorView(activityIndicatorStyle: .white)
        self.addSubview(self.loadingView!)
        
        self.stateLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 40))
        self.stateLabel?.textAlignment = .center
        self.stateLabel!.font = v2Font(12)
        self.addSubview(self.stateLabel!)
        
        self.noMoreDataStateString = "没有更多数据了"
        self.loadingView?.activityIndicatorViewStyle = .gray
        self.stateLabel!.textColor = UIColor(white: 0, alpha: 0.3)
        
//        self.thmemChangedHandler = {[weak self] (style) -> Void in
//            if V2EXColor.sharedInstance.style == V2EXColor.V2EXColorStyleDefault {
//                self?.loadingView?.activityIndicatorViewStyle = .gray
//                self?.stateLabel!.textColor = UIColor(white: 0, alpha: 0.3)
//            }
//            else{
//                self?.loadingView?.activityIndicatorViewStyle = .white
//                self?.stateLabel!.textColor = UIColor(white: 1, alpha: 0.3)
//            }
//        }
    }
    
    /**
     在这里设置子控件的位置和尺寸
     */
    override func placeSubviews(){
        super.placeSubviews()
        self.loadingView!.center = CGPoint(x: self.mj_w/2, y: self.mj_h/2 + self.centerOffset);
        self.stateLabel!.center = CGPoint(x: self.mj_w/2, y: self.mj_h/2  + self.centerOffset);
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
import FXBlurView
import UIKit
import SnapKit
import Alamofire
import AlamofireObjectMapper
import Ji
import MJRefresh
import Foundation
