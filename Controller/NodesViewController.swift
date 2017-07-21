import UIKit
class NodesViewController: UIViewController {
    fileprivate weak var _loadView:V2LoadingView?
    func showLoadingView (){
        self._loadView = V2LoadingView(view)
    }
    func hideLoadingView() {
        self._loadView?.hideLoadingView()
    }
    fileprivate var collectionView:CollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("Navigation")
        self.view.backgroundColor = V2EXColor.colors.v2_backgroundColor
        self.collectionView = CollectionView(frame: self.view.bounds)
        self.view.addSubview(self.collectionView!)
        NodeGroupModel.getNodes { (response) -> Void in
            if response.success {
                self.collectionView.nodeGroupArray = response.value
                self.collectionView?.reloadData()
            }
            self.hideLoadingView()
        }
        self.showLoadingView()
    }
}
fileprivate class CollectionView : TJCollectionView {
    convenience init(frame: CGRect){
        let layout = UICollectionViewFlowLayout();
        layout.sectionInset = UIEdgeInsetsMake(10, 15, 10, 15);
        self.init(frame:frame,collectionViewLayout:layout)
        registerCell(NodeCell.self)
        registerHeaderView(NodeView.self)
        backgroundColor = V2EXColor.colors.v2_CellWhiteBackgroundColor
    }
    var nodeGroupArray:[NodeGroupModel]?
    override func sectionCount() -> Int {
        if let count = self.nodeGroupArray?.count{
            return count
        }
        return 0
    }
    override func itemCount(_ section: Int) -> Int {
        return self.nodeGroupArray![section].children.count
    }
    override func cellAt(_ indexPath: IndexPath) -> UICollectionViewCell {
        let nodeModel = self.nodeGroupArray![indexPath.section].children[indexPath.row]
        let cell = dequeueCell(NodeCell.self,indexPath) as! NodeCell
        cell.textLabel.text = nodeModel.nodeName
        return cell;
    }
    override func viewFor(_ kind: String, _ indexPath: IndexPath) -> UICollectionReusableView {
        let view =  dequeueHeaderView(NodeView.self,indexPath) as! NodeView
        view.label.text = self.nodeGroupArray![indexPath.section].groupName
        return view
    }
    override func didSelectItemAt(_ indexPath: IndexPath){
        let nodeModel = self.nodeGroupArray![indexPath.section].children[indexPath.row]
        Msg.send("openNodeTopicList",[nodeModel.nodeId ,nodeModel.nodeName])
    }
    override func sizeFor(_ collectionViewLayout: UICollectionViewLayout, _ indexPath: IndexPath) -> CGSize {
        let nodeModel = self.nodeGroupArray![indexPath.section].children[indexPath.row]
        return CGSize(width: nodeModel.width, height: 25);
    }
    override func minimumInteritemSpacingForSectionAt(_ collectionViewLayout: UICollectionViewLayout, section: Int) -> CGFloat{
        return 15
    }
    override   func referenceSizeForHeaderIn(_  collectionViewLayout: UICollectionViewLayout, _ section: Int) -> CGSize{
        return CGSize(width: self.bounds.size.width, height: 35)
    }
}
fileprivate class NodeCell: UICollectionViewCell {
    var textLabel:UILabel = {
        let label = UILabel()
        label.font = v2Font(15)
//        label.textColor = V2EXColor.colors.v2_TopicListUserNameColor
//        label.backgroundColor = V2EXColor.colors.v2_CellWhiteBackgroundColor
        return label
    }()
    fileprivate override func layoutSubviews() {
        self.backgroundColor = V2EXColor.colors.v2_CellWhiteBackgroundColor
        self.contentView.addSubview(textLabel)
        textLabel.snp.remakeConstraints({ (make) -> Void in
            make.center.equalTo(self.contentView)
        })
    }
}
fileprivate class NodeView: UICollectionReusableView {
    var label : UILabel = {
        let _label = UILabel()
        _label.font = v2Font(16)
//        _label.textColor = V2EXColor.colors.v2_TopicListTitleColor
//        _label.backgroundColor = V2EXColor.colors.v2_backgroundColor
        return _label
    }()
    fileprivate override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundColor = V2EXColor.colors.v2_backgroundColor
        self.addSubview(label);
        label.snp.makeConstraints{
            $0.centerY.equalTo(self)
            $0.left.equalTo(self).offset(15)
        }
    }
}
