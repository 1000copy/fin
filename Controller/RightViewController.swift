import UIKit

class RightViewController: TJPage{
    fileprivate var _tableView :RightTable!
    fileprivate var tableView: RightTable {
        get{
            if(_tableView != nil){
                return _tableView!;
            }
            _tableView = RightTable();
            return _tableView!;
        }
    }
    class BlurView : TJBlur{
        var backgroundImageView:UIImageView?
        override func onLoad() {
            self.backgroundImageView = UIImageView()
            self.backgroundImageView!.frame = (self.owner?.frame)!
            self.backgroundImageView!.contentMode = .left
            backgroundImageView?.image = UIImage(named: "32.jpg")
            self.underlyingView = self.backgroundImageView!
            self.isDynamic = false
            self.frame = (owner?.frame)!
            self.tintColor = UIColor.black
            owner?.addSubview(underlyingView!)
            owner?.addSubview(self)
        }
    }
    override func onLoad() {
        self.view.backgroundColor = V2EXColor.colors.v2_backgroundColor;
        let _  = BlurView(view)
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints{ (make) -> Void in
            make.top.right.bottom.left.equalTo(self.view)
        }
        
    }
    func maxWidth() -> CGFloat{
        // 调整RightView宽度
        let cell = RightCell()
        let cellFont = UIFont(name: cell.nodeNameLabel.font.familyName, size: cell.nodeNameLabel.font.pointSize)
        for node in (tableView.tableData as! RightTableData).nodes {
            let str =  node["nodeName"] as! String
            let w = getFontWidth(str, cellFont!)
            let width = w + 50
            if width > 100 {
                return width
            }
        }
        return 100
    }
    func getFontWidth(_ str : String,_ cellFont : UIFont)-> CGFloat{
        let size = str.boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: CGFloat(MAXFLOAT)),
                                    options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                    attributes: ["NSFontAttributeName":cellFont],
                                    context: nil)
        return size.width
    }
   }

fileprivate class RightTableData : TJTableDataSource{
    let arr = ["tech","creative","play","apple","jobs","deals","city","qna","hot","all","r2","nodes","members",]
    var nodes : [TableDataSourceItem] = []
    override init() {
        for item in arr{
            var  a : TableDataSourceItem = [:]
            a["nodeName"] =  NSLocalizedString(item )
            a["nodeTab"] =  item
            nodes.append(a)
        }
    }
    override func rowCount(_ section: Int) -> Int {
        return nodes.count
    }
    override func rowHeight(_ indexPath: IndexPath) -> CGFloat {
        return 48
    }
//    when CellTypes is just one ,then cellTypeAt func may not write 
//    override func cellTypeAt(_ indexPath: IndexPath) -> UITableViewCell.Type {
//        return RightCell.self
//    }
    override func cellTypes() -> [UITableViewCell.Type] {
        return [RightCell.self]
    }
    override func getDataItem(_ indexPath: IndexPath) -> TableDataSourceItem {
        return nodes[indexPath.row]
    }
}

fileprivate class RightTable : TJTable{
    override func onLoad() {
        tableData = RightTableData()
        backgroundColor = UIColor.clear
        estimatedRowHeight=100;
        separatorStyle = .none;
        tableHeaderView = UIView()
        tableHeaderView?.frame = TJRect(0,0,SCREEN_WIDTH,20)

    }
    fileprivate override func didSelectRowAt(_ indexPath: IndexPath) {
        if(indexPath.row != self.currentSelectedTabIndex){
            let ip = IndexPath(row: currentSelectedTabIndex, section: 0)
            let cell = self.cellForRow(at: ip)
            cell?.setSelected(false, animated: false)
        }
        let cell = self.cellForRow(at: indexPath)
        cell?.setSelected(true, animated: false)
        currentSelectedTabIndex  = indexPath.row
        super.didSelectRowAt(indexPath)
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        var currentTab = Setting.shared.kHomeTab
        if currentTab == nil {
            currentTab = "all"
        }
        currentSelectedTabIndex = (tableData as! RightTableData).arr.index( of: currentTab!)!
        cell.setSelected(indexPath.row == self.currentSelectedTabIndex, animated: false)
    }
    var currentSelectedTabIndex = 0;
}
fileprivate class RightCell: TJCell {
    var data : PCTableDataSource?
    override func load(_ data : PCTableDataSource,_ item : TableDataSourceItem,_ indexPath : IndexPath){
        self.data = data
        nodeNameLabel.text = item["nodeName"] as? String
    }
    override func action(_ indexPath: IndexPath) {
        print(indexPath)
        let node = data?.getDataItem(indexPath)
        Msg.send("ChangeTab",[node?["nodeTab"] as! String])
        Msg.send("closeDrawer")
    }
    
    var nodeNameLabel: UILabel = {
        let label = UILabel()
        label.font = v2Font(15)
        return label
    }()
    
    var panel = UIView()
    override func setup(){
        self.selectionStyle = .none
        self.backgroundColor = UIColor.clear
        
        self.contentView.addSubview(panel)
        self.panel.snp.makeConstraints{ (make) -> Void in
            make.left.top.right.equalTo(self.contentView)
            make.bottom.equalTo(self.contentView).offset(-1 * SEPARATOR_HEIGHT)
        }
        
        panel.addSubview(self.nodeNameLabel)
        self.nodeNameLabel.snp.makeConstraints{ (make) -> Void in
            make.right.equalTo(panel).offset(-22)
            make.centerY.equalTo(panel)
        }
        
//        self.thmemChangedHandler = {[weak self] (style) -> Void in
            self.refreshBackgroundColor()
            self.nodeNameLabel.textColor = V2EXColor.colors.v2_LeftNodeTintColor
//        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated);
        self.refreshBackgroundColor()
    }
    func refreshBackgroundColor() {
        if self.isSelected {
            self.panel.backgroundColor = V2EXColor.colors.v2_LeftNodeBackgroundHighLightedColor
        }
        else{
            self.panel.backgroundColor = V2EXColor.colors.v2_LeftNodeBackgroundColor
        }
    }
}
