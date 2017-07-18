import UIKit
import FXBlurView
import Shimmer
class RelevantCommentsViewController: UIViewController{
    var commentsArray:[TopicCommentModel] = []
    fileprivate var _tableView :Table!
    override func viewDidLoad() {
        super.viewDidLoad()
        _tableView = Table(commentsArray);
        self.view.addSubview(self._tableView);
        self._tableView.snp.remakeConstraints{ (make) -> Void in
            make.left.right.top.bottom.equalTo(self.view);
        }
    }
}
fileprivate class Table: TJTable{
    init(_ commentsArray:[TopicCommentModel]){
        super.init(frame: CGRect.zero,style:.plain)
        self.tableData = DataRelevantComments(commentsArray)
        separatorStyle = .none;
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
class DataRelevantComments: NSObject ,PCTableDataSource{
    init(_ commentsArray:[TopicCommentModel] ) {
        self.commentsArray = commentsArray
    }
    var commentsArray:[TopicCommentModel] = []
    func sectionCount() -> Int{
        return 1
    }
    func rowCount(_ section: Int) -> Int{
        return self.commentsArray.count
    }
    func rowHeight(_ indexPath: IndexPath) -> CGFloat{
        return self.commentsArray[indexPath.row].getHeight()
    }
    func cellTypes() ->[UITableViewCell.Type]{
        return [TopicDetailCommentCell.self]
    }
    func getDataItem(_ indexPath : IndexPath) -> TableDataSourceItem{
        return commentsArray[indexPath.row].toDict()
    }
}
