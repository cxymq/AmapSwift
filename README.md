# AmapSwift
高德地图API的简单使用

环境：

Xcode10.1

Swift4.2

真机6s，ios11
 

高德地图API使用：
 

需要到[高德开发者平台](https://lbs.amap.com)申请开发者账号，创建应用，获取对应平台的key。

查看[API](https://lbs.amap.com/api)，也可到 示例代码 中获取官方demo。

具体实现：

第一步：cocoapod导入SDK，会引入基础SDK，默认集成了 IDFA 服务，提交AppSote请看[解决方案](https://lbs.amap.com/api/ios-location-sdk/guide/create-project/idfa-guide/)

pod 'AMapLocation'
注意：1.如果不想集成  IDFA服务，需要pod AMapLocation-NO-IDFA。

           2.为了能够正常使用地图API，需要引入桥接头文件AmapSwift_Bridging_Header_h，并且在TARGETS->Build Settings-> Swift Compiler - Code Generation -> Objective-C Bridging Header 引入路径。

具体查看demo。

 

第二步：申请权限

iOS11，在info.plist文件中添加以下字段：

NSLocationAlwaysAndWhenInUseUsageDescription和 NSLocationWhenInUseUsageDescription字段。

 

注意：

错误：Xcode会报错误==>library not found for -lstdc++.6.0.9’

原因：Xcode10.0以上，Apple废除了 libstdc++6.0.9（即lstdc++6.0.9），需要将其重新加入lib路径。

解决方法（[参考](https://www.jianshu.com/p/35d34828e607）)：下载libstdc++库，下载链接，提取码arms

将 libstdc++、libstdc++.6、libstdc++6.0.9拷贝到Xcode的如下目录：

1.真机环境：/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/lib/

2.模拟器环境：/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/lib/

 

第三步：构建项目

本Demo的控件大多是故事板拖拽完成，因 UISearchController 未找到相应的控件，使用代码构建。当然，所有拖拽空间皆可由代码完成。

初步学习集成可以先参考Demo中 单次定位部分内容，后续学习参考 搜索定位。Demo中有注释。

 

1.单次定位

用到 定位管理类（AMapLocationManager）、周边搜索设置类（AMapPOIAroundSearchRequest）、搜索类（AMapSearchAPI）和 地图视图类（MAMapView：用于显示地图、标注注解）。

 

初始化AMapLocationManager
```
        //初始化AMapLocationManager对象，设置代理。
		locationManager = AMapLocationManager()
		locationManager?.delegate = self
		// 带逆地理信息的一次定位（返回坐标和地址信息）
		locationManager?.desiredAccuracy = kCLLocationAccuracyHundredMeters
		//   定位超时时间，最低2s，此处设置为2s
		locationManager?.locationTimeout = 2
		//   逆地理请求超时时间，最低2s，此处设置为2s
		locationManager?.reGeocodeTimeout = 2
 ```

设置搜索项AMapPOIAroundSearchRequest
```
        searchRequest = AMapPOIAroundSearchRequest.init()
		///查询关键字，多个关键字用“|”分割
		searchRequest?.keywords = "商务住宅|餐饮服务|生活服务"
		///排序规则0-距离排序；1-综合排序, 默认0
		searchRequest?.sortrule = 0
		///每页记录数, 范围1-50, [default = 20]
		searchRequest?.offset = 50
		///是否返回扩展信息，默认为 NO。
		searchRequest?.requireExtension = true
 ```

请求带逆地理
```
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
 ```

2.搜索定位

用到 定位管理类（AMapLocationManager）、周边搜索设置类（AMapPOIAroundSearchRequest）、搜索类（AMapSearchAPI）和 地图视图类（MAMapView：用于显示地图、标注注解）。还有搜索控制器（UISearchController）等。

Demo中定义多个属性，都标有详细注释。如 dataArr（定位的周边结果）、tips（搜索返回的搜索结果）、tableView（显示周边结果）、searchResultview（显示搜索的结果）。

-----------------------------------------------------------

[个人博客](https://blog.csdn.net/Crazy_SunShine)

[Github](https://github.com/cxymq)

[个人公众号:Flutter小同学]  
![https://github.com/cxymq/Images/blob/master/0.失败预加载图片/error.jpg](https://github.com/cxymq/Images/blob/master/1.公众号二维码/qrcode.png)

[个人网站](http://chenhui.today/)
