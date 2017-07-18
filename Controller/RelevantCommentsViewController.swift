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
            let ds = DataRelevantComments()
            ds.commentsArray = commentsArray
            _tableView.tableData = ds
        
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
}
class TableRelevantComments: TJTable{
        override init(frame: CGRect, style: UITableViewStyle) {
            super.init(frame:frame,style:style)
            separatorStyle = .none;
        }
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    // in the layoutSubviews function and know if the view loaded.
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}
class DataRelevantComments: NSObject ,PCTableDataSource{
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
