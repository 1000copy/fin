import UIKit
class NodesViewController: BaseViewController {
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

fileprivate class CollectionView : CollectionViewBase {
    convenience init(frame: CGRect){
        let layout = V2LeftAlignedCollectionViewFlowLayout();
        layout.sectionInset = UIEdgeInsetsMake(10, 15, 10, 15);
        self.init(frame:frame,collectionViewLayout:layout)
        register(NodeTableViewCell.self, forCellWithReuseIdentifier: "cell")
        register(NodeCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "nodeGroupNameView")
        backgroundColor = V2EXColor.colors.v2_CellWhiteBackgroundColor
        dataSource = self
        delegate = self
    }
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var nodeGroupArray:[NodeGroupModel]?
    override func sectionCount() -> Int {
        if let count = self.nodeGroupArray?.count{
            return count
        }
        return 0
    }
    override func numberOfItemsIn(_ section: Int) -> Int {
        return self.nodeGroupArray![section].children.count
    }
    override func cellForItemAt(_ indexPath: IndexPath) -> UICollectionViewCell {
        let nodeModel = self.nodeGroupArray![indexPath.section].children[indexPath.row]
        let cell = self.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! NodeTableViewCell;
        cell.textLabel.text = nodeModel.nodeName
        return cell;
    }
    override func viewForSupplementaryElement(_ kind: String, _ indexPath: IndexPath) -> UICollectionReusableView {
        let nodeGroupNameView = self.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "nodeGroupNameView", for: indexPath)
        (nodeGroupNameView as! NodeCollectionReusableView).label.text = self.nodeGroupArray![indexPath.section].groupName
        return nodeGroupNameView
    }
    override func didSelectItemAt(_ indexPath: IndexPath){
        let nodeModel = self.nodeGroupArray![indexPath.section].children[indexPath.row]
        Msg.send("openNodeTopicList",[nodeModel.nodeId ,nodeModel.nodeName])
    }
    override func sizeForItemAt(_ collectionViewLayout: UICollectionViewLayout, _ indexPath: IndexPath) -> CGSize {
        let nodeModel = self.nodeGroupArray![indexPath.section].children[indexPath.row]
        return CGSize(width: nodeModel.width, height: 25);
    }
    override func minimumInteritemSpacingForSectionAt(_ collectionViewLayout: UICollectionViewLayout, section: Int) -> CGFloat{
        return 15
    }
    override   func referenceSizeForHeaderIn(_  collectionViewLayout: UICollectionViewLayout, _ section: Int) -> CGSize{
        return CGSize(width: self.bounds.size.width, height: 35);

    }
}
