//
//  FavoritesViewController.swift
//  V2ex-Swift
//
//  Created by huangfeng on 1/30/16.
//  Copyright © 2016 Fin. All rights reserved.
//

import UIKit

class FavoritesViewController: BaseViewController {
    var currentPage = 1
    //最大的Page
    var maxPage = 1
    fileprivate var _tableView :Table2!
    fileprivate var tableView: Table2 {
        get{
            if(_tableView != nil){
                return _tableView!;
            }
            _tableView = Table2();
            _tableView.backgroundColor = V2EXColor.colors.v2_backgroundColor
            _tableView.separatorStyle = UITableViewCellSeparatorStyle.none;
            regClass(_tableView, cell: HomeTopicListTableViewCell.self)
            return _tableView!;
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(hideLoadingView), name: Notification.Name("FavoritesViewControllerLoaded"), object: nil)
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
                    Msg.send("FavoritesViewControllerLoaded")
                }
            }
            cb()
        }
    }
    func getNextPage(_ cb : @escaping CallbackMore){
        if let count = self.tableView.topicList?.count, count <= 0 {
            self.tableView.endRefresh()
            return;
        }
        if self.currentPage >= maxPage {
            self.tableView.endRefresh(false)
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
class Table2 : TableBase{
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
