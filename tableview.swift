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
class  TableBase : RefreshableTableBase , UITableViewDataSource,UITableViewDelegate{
    // 子类接口区
    func onLoad(){
    }
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
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame:frame,style:style)
        self.dataSource = self
        self.delegate = self
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
class  RefreshableTableBase1 : UITableView {
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame:frame,style:style)
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
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    var scrollUp : ((_ cb : @escaping Callback)-> Void)?
    var scrollDown : ((_ cb : @escaping CallbackMore)-> Void)?
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
}
class  RefreshableTableBase : UITableView {
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame:frame,style:style)
        self.gtm_addRefreshHeaderView(delegate: self)
        self.gtm_addLoadMoreFooterView(delegate: self)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    var scrollUp : ((_ cb : @escaping Callback)-> Void)?
    var scrollDown : ((_ cb : @escaping CallbackMore)-> Void)?
    func beginScrollUp(){
       refresh()
    }
    func endScrollUp(){
        self.endRefreshing(isSuccess: true)
    }
    func endScrollDown(_ hasMoreData : Bool = true){
        self.endLoadMore(isNoMoreData: !hasMoreData)
    }
    func beginRefresh(){
        self.refresh()
    }
}

extension RefreshableTableBase:GTMRefreshHeaderDelegate{
    func refresh() {
        if scrollUp != nil{
            scrollUp!(){
                self.endRefreshing(isSuccess: true)
            }
        }
    }
}
extension RefreshableTableBase: GTMLoadMoreFooterDelegate {
    func loadMore() {
        if scrollDown != nil{
            scrollDown!(){
                self.endLoadMore(isNoMoreData: !$0)
            }
        }
    }
}

import MJRefresh
import UIKit
import GTMRefresh
