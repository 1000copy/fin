import UIKit
import FXBlurView
import Shimmer
class RelevantCommentsViewController: UIViewController, UITableViewDelegate,UITableViewDataSource {

    var commentsArray:[TopicCommentModel] = []
    fileprivate var dismissing = false
    fileprivate var _tableView :UITableView!
    fileprivate var tableView: UITableView {
        get{
            if(_tableView != nil){
                return _tableView!;
            }
            _tableView = UITableView();
            _tableView.separatorStyle = UITableViewCellSeparatorStyle.none;
            
//            _tableView.backgroundColor = UIColor.clear
//            _tableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0)
            regClass(_tableView, cell: TopicDetailCommentCell.self)
            
            _tableView.delegate = self
            _tableView.dataSource = self
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.commentsArray.count;
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        let layout = self.commentsArray[indexPath.row].textLayout!
//        return layout.textBoundingRect.size.height + 12 + 35 + 12 + 12 + 1
        return self.commentsArray[indexPath.row].getHeight()
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = getCell(tableView, cell: TopicDetailCommentCell.self, indexPath: indexPath)
        cell.bind(self.commentsArray[indexPath.row])
        return cell
    }
    
    
}
