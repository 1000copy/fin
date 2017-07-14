typealias TJCell = CellBase
typealias TJTable = DataTableBase
typealias TJTableDataSource = TableDataSource
typealias TJTableDataSourceItem = TableDataSourceItem

// Button,TableView,CollectView
import UIKit
import SnapKit

import Alamofire
import AlamofireObjectMapper

import Ji
import MJRefresh

import Foundation
class  Table : TableBase {
    var topicList:Array<TopicListModel>?
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame:frame,style:style)
        separatorStyle = UITableViewCellSeparatorStyle.none;
        regClass(self, cell: HomeTopicListTableViewCell.self);
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    override func sectionCount() -> Int {
        return 1
    }
    override func rowCount(_ section: Int) -> Int {
        if let list = self.topicList {
            return list.count;
        }
        return 0;
    }
    override func rowHeight(_ indexPath: IndexPath) -> CGFloat {
        let item = self.topicList![indexPath.row]
        let titleHeight = item.topicTitleLayout?.textBoundingRect.size.height ?? 0
        let height = fixHeight ()  + titleHeight
        return height
    }
    override  func cellAt(_ indexPath: IndexPath) -> UITableViewCell{
        let cell = getCell(self, cell: HomeTopicListTableViewCell.self, indexPath: indexPath);
        cell.bind(self.topicList![indexPath.row]);
        return cell;
    }
    override func didSelectRowAt(_ indexPath: IndexPath) {
        let item = self.topicList![indexPath.row]
        if let id = item.topicId {
            let a = {[weak self] (topicId : String)->Void in
                self?.perform(#selector(self?.ignoreTopicHandler(_:)), with: topicId, afterDelay: 0.6)
            }
            Msg.send("openTopicDetail",[id,a])
            deselectRow(at: indexPath, animated: true);
        }
    }
    func fixHeight()-> CGFloat{
        let height = 12    +  35     +  12    +  12      + 8
        return CGFloat(height)
        //          上间隔   头像高度  头像下间隔     标题下间隔 cell间隔
    }
    // 当用户点击忽略按钮（在TopicDetailController内），执行它
    func ignoreTopicHandler(_ topicId:String) {
        let index = self.topicList?.index(where: {$0.topicId == topicId })
        if index == nil {
            return
        }
        //看当前忽略的cell 是否在可视列表里
        let indexPaths = indexPathsForVisibleRows
        let visibleIndex =  indexPaths?.index(where: {($0 as IndexPath).row == index})
        
        self.topicList?.remove(at: index!)
        //如果不在可视列表，则直接reloadData 就可以
        if visibleIndex == nil {
            reloadData()
            return
        }
        //如果在可视列表，则动画删除它
        beginUpdates()
        deleteRows(at: [IndexPath(row: index!, section: 0)], with: .fade)
        endUpdates()
    }
    
}

class DataTableBase : TableBase{
    var tableData_ : TableDataSource!
    var tableData : TableDataSource!{
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
        cell.load(tableData,tableData.getDataItem(indexPath), indexPath)
        return cell ;
    }
    func cellTypeAt(_ indexPath: IndexPath) -> UITableViewCell.Type{
        if cellTypes().count == 1 {
            return cellTypes()[0]
        }else if tableData != nil{
            return tableData.cellTypeAt(indexPath)
        }
        return UITableViewCell.self
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
class TableDataSource : NSObject{
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
    func load(_ data : TableDataSource,_ item : TableDataSourceItem,_ indexPath : IndexPath){
        
    }
    func loadCell(_ data : TableDataSourceItem){
        
    }
    
    func action(_ indexPath : IndexPath){
    }
    // imple
    func deselect(){
        tableView?.deselectRow(at:(tableView?.indexPath(for: self))!,animated: true)
    }
    var tableView: UITableView? {
        var view = self.superview
        while (view != nil && view!.isKind(of: UITableView.self) == false) {
            view = view!.superview
        }
        return view as? UITableView
    }
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier);
        self.setup();
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
    func numberOfItemsIn(_ section: Int) -> Int {
        return 0
    }
    func cellForItemAt(_ indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
    func viewForSupplementaryElement(_ kind: String, _ indexPath: IndexPath) -> UICollectionReusableView {
        return UICollectionReusableView()
    }
    func didSelectItemAt(_ indexPath: IndexPath){
    }
    func sizeForItemAt(_ collectionViewLayout: UICollectionViewLayout, _ indexPath: IndexPath) -> CGSize {
        return CGSize(width: 0, height: 0);
    }
    func minimumInteritemSpacingForSectionAt(_ collectionViewLayout: UICollectionViewLayout, section: Int) -> CGFloat{
        return 0.0
    }
    func referenceSizeForHeaderIn(_  collectionViewLayout: UICollectionViewLayout, _ section: Int) -> CGSize{
        return CGSize(width: self.bounds.size.width, height: 35);
    }
    
    // implements
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        didSelectItemAt(indexPath)
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sectionCount()
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItemsIn(section)
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return cellForItemAt(indexPath)
    }
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return viewForSupplementaryElement(kind, indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return sizeForItemAt(collectionViewLayout,indexPath)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat{
        return minimumInteritemSpacingForSectionAt(collectionViewLayout, section: section)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
        return referenceSizeForHeaderIn(collectionViewLayout, section)
    }
}
class ButtonBase : UIButton{
    var touchUp_ : Callback?
    var touchUp : Callback?{
        get{
            return touchUp_
        }
        set{
            touchUp_ = newValue
        }
    }
    func doTouchUp(){
        if let t = touchUp {
            t()
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addTarget(self, action: #selector(doTouchUp), for: .touchUpInside)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        
        self.thmemChangedHandler = {[weak self] (style) -> Void in
            if V2EXColor.sharedInstance.style == V2EXColor.V2EXColorStyleDefault {
                self?.loadingView?.activityIndicatorViewStyle = .gray
                self?.arrowImage?.tintColor = UIColor.gray
            }
            else{
                self?.loadingView?.activityIndicatorViewStyle = .white
                self?.arrowImage?.tintColor = UIColor.gray
            }
        }
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
        
        self.thmemChangedHandler = {[weak self] (style) -> Void in
            if V2EXColor.sharedInstance.style == V2EXColor.V2EXColorStyleDefault {
                self?.loadingView?.activityIndicatorViewStyle = .gray
                self?.stateLabel!.textColor = UIColor(white: 0, alpha: 0.3)
            }
            else{
                self?.loadingView?.activityIndicatorViewStyle = .white
                self?.stateLabel!.textColor = UIColor(white: 1, alpha: 0.3)
            }
        }
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
}
