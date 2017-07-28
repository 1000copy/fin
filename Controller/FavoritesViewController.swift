import UIKit
class FavoritesViewController: UIViewController {
    fileprivate weak var _loadView:V2LoadingView?
    func showLoadingView (){
        self._loadView = V2LoadingView(view)
    }
    
    func hideLoadingView() {
        self._loadView?.hideLoadingView()
    }
    fileprivate var _tableView :FavTable!
    fileprivate var tableView: FavTable {
        get{
            if(_tableView != nil){
                return _tableView!;
            }
            _tableView = FavTable();
            return _tableView!;
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("favorites")
        self.view.backgroundColor = V2EXColor.colors.v2_backgroundColor
        self.view.addSubview(self.tableView);
        self.tableView.snp.makeConstraints{ (make) -> Void in
            make.top.right.bottom.left.equalTo(self.view);
        }
        self.showLoadingView()
        Msg.observe(self, #selector(hideLoadingView), "favTableLoaded")
        self.tableView.beginRefresh()
    }
}
class FavData : HomeData{
    override func cellTypes() -> [UITableViewCell.Type] {
        return [FavCell.self]
    }
}
class FavCell : HomeTopicListTableViewCell{
    var data: PCTableDataSource?
    override func action(_ indexPath: IndexPath) {
        let item = self.data?.getDataItem(indexPath)
        if let id = item?["topicId"] as? String{
            Msg.send("openTopicDetail1",[id])
        }
        deselect()
    }
    override func load(_ data: PCTableDataSource, _ item: TableDataSourceItem, _ indexPath: IndexPath) {
        self.data = data
        super.load(data, item, indexPath)
    }
}
fileprivate class FavTable : TJTable{
    var currentPage = 1
    func refresh(_ cb : @escaping Callback){
        self.currentPage = 1
        TopicListModelHTTP.getFavoriteList{
            [weak self](response) -> Void in
            if response.success {
                if let weakSelf = self , let list = response.value?.0 , let maxPage = response.value?.1{
                    weakSelf.topicList = list
                    weakSelf.maxPage = maxPage
                    weakSelf.reloadData()
                    Msg.send("favTableLoaded")
                }
            }
            cb()
        }
    }
    func getNextPage(_ cb : @escaping CallbackMore){
        if self.topicList?.count == 0 {
            self.endScrollDown()
            return;
        }
        if self.currentPage >= maxPage {
            self.endScrollDown(false)
            return;
        }
        self.currentPage += 1
        TopicListModelHTTP.getFavoriteList(self.currentPage) {[weak self] (response) -> Void in
            if response.success {
                if let weakSelf = self ,let list = response.value?.0 {
                    weakSelf.topicList! += list
                    weakSelf.reloadData()
                }
                else{
                    self?.currentPage -= 1
                }
            }
            cb(true)
        }
    }
    //最大的Page
    var maxPage = 1
    var topicList:[TopicListModel]?{
        get{
            return homedata?.topicList
        }
        set{
            homedata?.topicList = newValue
        }
    }
    var homedata :  FavData?
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame:frame,style:style)
        separatorStyle = UITableViewCellSeparatorStyle.none;
        homedata =  FavData()
        tableData = homedata
        self.scrollUp = refresh
        self.scrollDown = getNextPage
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
