import UIKit
import FXBlurView
import Shimmer

class RelevantCommentsViewController: UIViewController{
//class RelevantCommentsViewController: UIViewController, UITableViewDelegate,UITableViewDataSource {

    var commentsArray:[TopicCommentModel] = []
    fileprivate var dismissing = false
    fileprivate var _tableView :TableRelevantComments!
    fileprivate var tableView: TableRelevantComments {
        get{
            if(_tableView != nil){
                return _tableView!;
            }
            _tableView = TableRelevantComments();
            _tableView.commentsArray = commentsArray
            _tableView.separatorStyle = UITableViewCellSeparatorStyle.none;
//            regClass(_tableView, cell: TopicDetailCommentCell.self)
//            _tableView.delegate = self
//            _tableView.dataSource = self
            return _tableView!;
            
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.tableView);
        self.tableView.snp.remakeConstraints{ (make) -> Void in
            make.left.right.top.bottom.equalTo(self.view);
        }
    }
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return self.commentsArray.count;
//    }
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return self.commentsArray[indexPath.row].getHeight()
//    }
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = getCell(tableView, cell: TopicDetailCommentCell.self, indexPath: indexPath)
//        cell.bind(self.commentsArray[indexPath.row])
//        return cell
//    }
}
class TableRelevantComments: TJTable{
    var commentsArray:[TopicCommentModel] = []
    override func cellTypes() -> [UITableViewCell.Type] {
        return [TopicDetailCommentCell.self]
    }
    override func rowCount(_ section: Int) -> Int {
        return self.commentsArray.count;
    }
    override func rowHeight(_ indexPath: IndexPath) -> CGFloat {
        return self.commentsArray[indexPath.row].getHeight()
    }
    override func getDataItem(_ indexPath: IndexPath) -> TableDataSourceItem {
        return commentsArray[indexPath.row].toDict()
    }
}
