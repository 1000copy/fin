import UIKit
class FavoritesViewController: UIViewController {
    fileprivate weak var _loadView:V2LoadingView?
    func showLoadingView (){
        self._loadView = V2LoadingView(view)
    }
    
    func hideLoadingView() {
        self._loadView?.hideLoadingView()
    }
    var currentPage = 1
    //最大的Page
    var maxPage = 1
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
        self.tableView.scrollUp = refresh
        self.tableView.scrollDown = getNextPage
        self.tableView.beginRefresh()
    }
    func refresh(_ cb : @escaping Callback){
        self.currentPage = 1
        TopicListModel.getFavoriteList{
            [weak self](response) -> Void in
            if response.success {
                if let weakSelf = self , let list = response.value?.0 , let maxPage = response.value?.1{
                    weakSelf.tableView.topicList = list
                    weakSelf.maxPage = maxPage
                    weakSelf.tableView.reloadData()
                    weakSelf.hideLoadingView()
                }
            }
            cb()
        }
    }
    func getNextPage(_ cb : @escaping CallbackMore){
        if self.tableView.topicList?.count == 0 {
            self.tableView.endScrollDown()
            return;
        }
        if self.currentPage >= maxPage {
            self.tableView.endScrollDown(false)
            return;
        }
        self.currentPage += 1
        TopicListModel.getFavoriteList(self.currentPage) {[weak self] (response) -> Void in
            if response.success {
                if let weakSelf = self ,let list = response.value?.0 {
                    weakSelf.tableView.topicList! += list
                    weakSelf.tableView.reloadData()
                }
                else{
                    self?.currentPage -= 1
                }
            }
            cb(true)
        }
    }
}
fileprivate class FavTable : TableBase{
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame:frame,style:style)
        backgroundColor = V2EXColor.colors.v2_backgroundColor
        separatorStyle = UITableViewCellSeparatorStyle.none;
        regClass(self, cell: HomeTopicListTableViewCell.self)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var topicList:[TopicListModel]?
    override func rowHeight(_ indexPath: IndexPath) -> CGFloat {
        let item = self.topicList![indexPath.row]
        let titleHeight = item.topicTitleLayout?.textBoundingRect.size.height ?? 0
        //          上间隔   头像高度  头像下间隔       标题高度    标题下间隔 cell间隔
        let height = 12    +  35     +  12      + titleHeight   + 12      + 8
        return height
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
    override func cellAt(_ indexPath: IndexPath) -> UITableViewCell{
        let cell = getCell(self, cell: HomeTopicListTableViewCell.self, indexPath: indexPath);
        cell.bind(self.topicList![indexPath.row]);
        return cell;
    }

    override func didSelectRowAt(_ indexPath: IndexPath) {
        let item = self.topicList![indexPath.row]
        if let id = item.topicId {
            Msg.send("openTopicDetail1",[id])
            self.deselectRow(at: indexPath, animated: true);
        }
    }
}
