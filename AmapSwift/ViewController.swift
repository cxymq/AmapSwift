//
//  ViewController.swift
//  AmapSwift
//
//  Created by Qi Wang on 2019/7/5.
//  Copyright © 2019 Qi Wang. All rights reserved.
//

import UIKit

class ViewController: UIViewController, AMapLocationManagerDelegate, MAMapViewDelegate, AMapSearchDelegate {
	
	var locationManager: AMapLocationManager?
	
	@IBOutlet weak var textView: UITextView!
	
	@IBOutlet weak var maMapView: MAMapView!
	
	var searchRequest: AMapPOIAroundSearchRequest?
	var searchAPI: AMapSearchAPI?
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		//初始化AMapLocationManager对象，设置代理。
		locationManager = AMapLocationManager()
		locationManager?.delegate = self
		// 带逆地理信息的一次定位（返回坐标和地址信息）
		locationManager?.desiredAccuracy = kCLLocationAccuracyHundredMeters
		//   定位超时时间，最低2s，此处设置为2s
		locationManager?.locationTimeout = 2
		//   逆地理请求超时时间，最低2s，此处设置为2s
		locationManager?.reGeocodeTimeout = 2
		
		//地图需要v4.5.0及以上版本才必须要打开此选项（v4.5.0以下版本，需要手动配置info.plist）
		AMapServices.shared().enableHTTPS = true
		
		maMapView.delegate = self
		//如果您需要进入地图就显示定位小蓝点，则需要下面两行代码
		maMapView.isShowsUserLocation = true
		maMapView.userTrackingMode = .follow
		maMapView.zoomLevel = 17
		
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
	}
	
	@IBAction func startLocationClick(_ sender: Any) {
		// 带逆地理（返回坐标和地址信息）。将下面代码中的 true 改成 false ，则不会返回地址信息。
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
			
			var addressInfo: String = ""
			
			
			if let location = location {
				NSLog("location:%@", location)
				
				addressInfo.append("经纬度：\(location.coordinate) \n")
			}
			
			if let reGeocode = reGeocode {
				NSLog("reGeocode:%@", reGeocode)
				
				addressInfo.append("国家：\(String(describing: reGeocode.country))\n")
				addressInfo.append("省份：\(String(describing: reGeocode.province))\n")
				addressInfo.append("城市：\(String(describing: reGeocode.city))\n")
				addressInfo.append("区：\(String.init(format: "%@", reGeocode.district))\n")
				addressInfo.append("街道：\(String.init(format: "%@", reGeocode.street))\n")
				addressInfo.append(contentsOf: "详细地址：\(String(describing: reGeocode.formattedAddress))\n")
			}
			
			self.textView.text = addressInfo
		})
	}
	
	@IBAction func searchLocationClick(_ sender: Any) {
		
	}
	
}
