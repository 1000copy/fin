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
            Msg.send("open topic detail",[id,a])
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
    }
    func canEditRowAt(_ indexPath: IndexPath) -> Bool {
        return true
    }
    func commitDelete(_ indexPath: IndexPath){
        
    }
    func commitInsert(_ indexPath: IndexPath){
        
    }
    // 实现区
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
//NotificationCenter.default.post(name: Notification.Name("dive2"), object: [id,a])
//NotificationCenter.default.addObserver(self, selector: #selector(dive2), name: Notification.Name("open topic detail"), object: nil)
class Msg {
    class func send( _ name : String, _ object : Any?){
        NotificationCenter.default.post(name: Notification.Name(name), object: object)
    }
    class func send( _ name : String){
        send(name,nil)
    }
    
    //    class func observe(_ owner : NSObject , responser : Any? , _ msg : String, _ object : Any?){
    //        NotificationCenter.default.addObserver(owner, selector: #selector(responser), name: Notification.Name(msg), object: nil)
    //    }
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
