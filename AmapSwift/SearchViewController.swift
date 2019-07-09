//
//  SearchViewController.swift
//  AmapSwift
//
//  Created by Qi Wang on 2019/7/8.
//  Copyright © 2019 Qi Wang. All rights reserved.
//

import UIKit


let SearchBarHeight: CGFloat = 44.0

class SearchViewController: UIViewController, AMapLocationManagerDelegate, MAMapViewDelegate, AMapSearchDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
	
	var dataArr: Array<AMapPOI>?
	
	var locationManager: AMapLocationManager?

	//搜索视图
	var searchController: UISearchController = UISearchController.init(searchResultsController: nil)
//	var searchResultView: UITableView =  UITableView.init(frame: CGRect.init(x: 0, y: 64, width: UIScreen.init().bounds.size.width, height: UIScreen.init().bounds.size.height - 64))
	@IBOutlet weak var searchResultView: UITableView!
	
	//地图视图
	@IBOutlet weak var mapView: MAMapView!
	//显示查询周边结果
	@IBOutlet weak var tableView: UITableView!
	//搜索框的top约束
	@IBOutlet weak var searchBarTopConstraints: NSLayoutConstraint!
	//地图的height约束
	@IBOutlet weak var mapViewHeightConstraints: NSLayoutConstraint!
	
	//搜索周边的位置当前页
	var currentPage: Int = 1
	
	//周边搜索设置项
	var searchRequest: AMapPOIAroundSearchRequest?
	//周边搜索对象
	var searchAPI: AMapSearchAPI?
	
	//当前经纬度对象
	var currentLocationCoordinate2D: CLLocationCoordinate2D?
	//当前位置注解对象
	var currentLocationAnnotation: MAPointAnnotation?
	
	//当前城市，用与搜索功能
	var currentCity: String?
	
	//判断是否处于搜索状态
	var isSearchStatus: Bool?
	
	//输入关键字搜索返回的搜索结果
	var tips: Array<AMapTip> = Array.init()
	
	//是否手动点击了地址
	var isSelectedAddress: Bool?
	
	
	override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		dataArr = Array.init()

		//设置搜索控制器
		searchController = UISearchController.init(searchResultsController: nil)
		searchController.delegate = self
		searchController.searchResultsUpdater = self
		//搜索时，背景变暗
		searchController.dimsBackgroundDuringPresentation = false
		let searchBar = self.searchController.searchBar
		searchBar.frame = CGRect.init(x: 0, y: 64, width: self.view.frame.size.width, height: SearchBarHeight)
		searchBar.barStyle = .default
		searchBar.isTranslucent = true
		self.view.addSubview(searchBar)
		
		//初始化AMapLocationManager对象，设置代理。
		locationManager = AMapLocationManager()
		locationManager?.delegate = self
		// 带逆地理信息的一次定位（返回坐标和地址信息）
		locationManager?.desiredAccuracy = kCLLocationAccuracyHundredMeters
		//   定位超时时间，最低2s，此处设置为2s
		locationManager?.locationTimeout = 5
		//   逆地理请求超时时间，最低2s，此处设置为2s
		locationManager?.reGeocodeTimeout = 5
		
		tableView.mj_footer = MJRefreshAutoNormalFooter.init(refreshingBlock: {
			//下拉刷新获取下一页内容
			self.currentPage += 1
			self.searchRequest?.page = self.currentPage
			self.searchRequest?.location = AMapGeoPoint.location(withLatitude: CGFloat(self.currentLocationCoordinate2D?.latitude ?? 0), longitude: CGFloat(self.currentLocationCoordinate2D?.longitude ?? 0))
			self.searchAPI?.aMapPOIAroundSearch(self.searchRequest)
		})
		
		mapView.delegate = self
		//如果您需要进入地图就显示定位小蓝点，则需要下面两行代码
		mapView.isShowsUserLocation = true
		mapView.userTrackingMode = .follow
		//缩放比例
		mapView.zoomLevel = 18
		
		searchRequest = AMapPOIAroundSearchRequest.init()
		///查询关键字，多个关键字用“|”分割
		searchRequest?.keywords = "商务住宅|餐饮服务|生活服务"
		///排序规则0-距离排序；1-综合排序, 默认0
		searchRequest?.sortrule = 0
		///每页记录数, 范围1-50, [default = 20]
		searchRequest?.offset = 50
		///是否返回扩展信息，默认为 NO。
		searchRequest?.requireExtension = true
		
		searchAPI = AMapSearchAPI.init()
		searchAPI?.delegate = self
		
		//开始定位
		startLocation()
    }
	
	//MARK:------搜索控制器的相关代理UISearchResultsUpdating && UISearchControllerDelegate
	func updateSearchResults(for searchController: UISearchController) {
		if searchController.searchBar.text?.count == 0 {
			return
		}
		
		searchResultView.isHidden = false
		
		let tips = AMapInputTipsSearchRequest.init()
		tips.keywords = searchController.searchBar.text
		tips.city = currentCity
		//搜索输入的地点
		searchAPI?.aMapInputTipsSearch(tips)

	}
	
	func willPresentSearchController(_ searchController: UISearchController) {
		searchController.searchBar.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: SearchBarHeight)
		
	}
	
	func didDismissSearchController(_ searchController: UISearchController) {
		searchController.searchBar.frame = CGRect.init(x: 0, y: 64, width: self.view.frame.size.width, height: SearchBarHeight)
		
	}

	//MARK:------带逆地理的单次定位
	func startLocation() {
		locationManager?.requestLocation(withReGeocode: true, completionBlock: { (location: CLLocation?, reGeocode: AMapLocationReGeocode?, error: Error?) in
			if let error = error {
				let error = error as NSError
				
				if error.code == AMapLocationErrorCode.locateFailed.rawValue {
					//定位错误：此时location和regeocode没有返回值，不进行annotation的添加
					NSLog("定位错误:{\(error.code) - \(error.localizedDescription)};")
					return
				}
				else if error.code == AMapLocationErrorCode.reGeocodeFailed.rawValue
					|| error.code == AMapLocationErrorCode.timeOut.rawValue
					|| error.code == AMapLocationErrorCode.cannotFindHost.rawValue
					|| error.code == AMapLocationErrorCode.badURL.rawValue
					|| error.code == AMapLocationErrorCode.notConnectedToInternet.rawValue
					|| error.code == AMapLocationErrorCode.cannotConnectToHost.rawValue {
					
					//逆地理错误：在带逆地理的单次定位中，逆地理过程可能发生错误，此时location有返回值，regeocode无返回值，进行annotation的添加
					NSLog("逆地理错误:{\(error.code) - \(error.localizedDescription)};")
				}
				else {
					//没有错误：location有返回值，regeocode是否有返回值取决于是否进行逆地理操作，进行annotation的添加
				}
			}
			
			if let location = location {
				NSLog("location:%@", location)
				
				//单次定位之后，根据关键字进行周边搜索
				self.currentLocationCoordinate2D = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
				self.searchRequest?.location = AMapGeoPoint.location(withLatitude: CGFloat(location.coordinate.latitude), longitude: CGFloat(location.coordinate.longitude))
				self.searchAPI?.aMapPOIAroundSearch(self.searchRequest)
			}
			
			if let reGeocode = reGeocode {
				NSLog("reGeocode:%@", reGeocode)
				
				self.currentCity = reGeocode.city
				//单次定位之后，设置位置注解
				self.setCenterLocation(reGeocode: reGeocode)
			}
		})
	}
	
	//MARK:------mapView 设置 注解annotation
	func setCenterLocation(reGeocode: AMapLocationReGeocode?) {
		if let currentLocation = currentLocationCoordinate2D {
			setCenterLocationAnnotation(locationCoordinate2d: currentLocation, title: reGeocode!.district, subtitle: reGeocode!.street)
		}
	}
	
	func setCenterLocationAnnotation(locationCoordinate2d: CLLocationCoordinate2D, title: String, subtitle: String) {
		//此处防止出现多个注解
		if let currentAnnotation = currentLocationAnnotation {
			mapView.removeAnnotation(currentAnnotation)
		}
		let pointAnnotation = MAPointAnnotation.init()
		pointAnnotation.coordinate = locationCoordinate2d
		pointAnnotation.title = title
		pointAnnotation.subtitle = subtitle
		mapView.addAnnotation(pointAnnotation)
		
		currentLocationAnnotation = pointAnnotation
	}
	
	//MARK:------地图标注以及拖动地图中心点不变 MAMapViewDelegate
	func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
		if annotation.isKind(of: MAPointAnnotation.self) {
			let pointReuseIndentifier = "pointReuseIndentifier"
			var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: pointReuseIndentifier)
			if annotationView == nil {
				annotationView = MAPinAnnotationView.init(annotation: annotation, reuseIdentifier: pointReuseIndentifier)
			}
			//设置气泡可以弹出，默认为false
			annotationView?.canShowCallout = true
			//设置标注可以拖动，默认为false
			annotationView?.isDraggable = true

			return annotationView
		}
		return nil
	}
	
	func mapView(_ mapView: MAMapView!, regionDidChangeAnimated animated: Bool) {
		mapView.removeAnnotations(mapView.annotations)
		
		//获取中心坐标
		let centerCoordiante = mapView.region.center
		currentLocationCoordinate2D = centerCoordiante
		
		//标记中心注解
		let centerAnnotation = MAPointAnnotation.init()
		centerAnnotation.coordinate = centerCoordiante
		centerAnnotation.title = ""
		centerAnnotation.subtitle = ""
		mapView.addAnnotation(centerAnnotation)
		
		if isSelectedAddress == false {
			currentPage = 1
			
			tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
			searchRequest?.location = AMapGeoPoint.location(withLatitude: CGFloat(centerCoordiante.latitude), longitude: CGFloat(centerCoordiante.longitude))
			searchAPI?.aMapPOIAroundSearch(searchRequest)
		}
		
		isSelectedAddress = false
		
	}
	
	//MARK:------周边查询的回调AMapSearchDelegate
	//POI查询回调函数
	func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
		let remoteArr: Array = response.pois
		if currentPage == 1 {
			dataArr = remoteArr
		} else {
			dataArr?.append(contentsOf: remoteArr)
		}
		
		if remoteArr.count < 50 {
			tableView.mj_footer.endRefreshingWithNoMoreData()
		} else {
			tableView.mj_footer.endRefreshing()
		}
		
		tableView.reloadData()
	}
	
	//输入提示查询回调函数
	func onInputTipsSearchDone(_ request: AMapInputTipsSearchRequest!, response: AMapInputTipsSearchResponse!) {
		if	let remoteArr = response.tips {
			tips = remoteArr
			//处于搜索状态
			isSearchStatus = true
			searchResultView.reloadData()
		}
	}
	
	//MARK:------展示周边地点以及搜索的周边 UITableViewDelegate && UITableViewDataSource
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 60
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if tableView == self.tableView {
			return (dataArr?.count)!
		}
		return tips.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cellID = "Cell"
		var cell = tableView.dequeueReusableCell(withIdentifier: cellID)
		if cell == nil {
			cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: cellID)
		}
		if tableView == self.tableView {
			let mapPOI = dataArr?[indexPath.row]
			if let t_mapPOI = mapPOI {
				cell?.textLabel?.text = t_mapPOI.name
				cell?.detailTextLabel?.text = t_mapPOI.address
			}
		} else {
			let tip = tips[indexPath.row]
			
			cell?.textLabel?.text = tip.name
			cell?.detailTextLabel?.text = tip.district
		}
		return cell!
		
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if tableView == self.tableView {
			let mapPOI = dataArr?[indexPath.row]
			if let t_mapPOI = mapPOI {
				if let location = t_mapPOI.location {
					let locationCoorinate = CLLocationCoordinate2D(latitude: Double(location.latitude), longitude: Double(location.longitude))
					//地图显示中心点以及注解跟随点击变化
					mapView.setCenter(locationCoorinate, animated: true)
					setCenterLocationAnnotation(locationCoordinate2d: locationCoorinate, title: t_mapPOI.name, subtitle: t_mapPOI.address)
				}
				
			}
		} else {
			
			let tip = tips[indexPath.row]
			if let location = tip.location {
				let locationCoorinate = CLLocationCoordinate2D(latitude: Double(location.latitude), longitude: Double(location.longitude))
				//地图显示中心点以及注解跟随点击变化
				mapView.setCenter(locationCoorinate, animated: true)
				setCenterLocationAnnotation(locationCoordinate2d: locationCoorinate, title: tip.name, subtitle: tip.address)
				isSelectedAddress = true
				
				searchResultView.isHidden = true
				//搜索框取消搜索状态
				searchController.isActive = false
				
				searchRequest?.location = AMapGeoPoint.location(withLatitude: location.latitude, longitude: location.longitude)
				searchAPI?.aMapPOIAroundSearch(searchRequest)
			}
			
		}
	}
	
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
