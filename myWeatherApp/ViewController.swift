//
//  ViewController.swift
//  myWeatherApp
//
//  Created by Vyacheslav on 30.10.2023.
//

import UIKit
import Reachability
import CoreData

class ViewController: UIViewController {

    //topLabels
    @IBOutlet private weak var cityLabel: UILabel!
    @IBOutlet private weak var degreesLabel: UILabel!
    @IBOutlet private weak var characteristicLabel: UILabel!
    @IBOutlet private weak var feelsLikeLabel: UILabel!

    //tableView + collectionView
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var scrollView: UIScrollView!
    
    //arrays for tableView
    private var namesOfDaysWeekArray = [String]()
    private var forecastMinTempADayArray = [Int]()
    private var forecastMaxTempADayArray = [Int]()
    private var forecastWeatherForDayArray = [String]()

    //arrays for collectionView
    private var collectionHoursArray = [String]()
    private var collectionDegreesArray = [Int]()
    private var collectionCharacteristicWeahter = [String]()
    
    private var dateFormatter: DateFormatter = DateFormatter()
    private var currentTimeForForecast: String = ""

    private let reachability = try! Reachability()
    
    private var isConnected : Bool = true

    private enum WeatherType: String {
        
        case cloudsSometimes = "Переменная облачность"
        case littleSnow = "Небольшой снег"
        case littleColdRain = "Слабый переохлажденный дождь"
        case littleDark = "Пасмурно"
        case cloudy = "Облачно"
        case littleRainWithSnow = "Небольшой дождь со снегом"
        case sometimesSnow = "Местами умеренный снег"
        case fog = "Дымка"
        case coldFog = "Переохлажденный Туман"
        case sunny = "Солнечно"
        case clear = "Ясно"
        case sometimesRain = "Местами дождь"
        case strongSnow = "Сильный снег"
        case veryStrongSnow = "Очень сильный снег"
        case averageSnow = "Умеренный снег"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        customTableView()
        customCollectionView()
        checkForConnection()
        if characteristicLabel.text != "" {
            setBackground()
        }
    }
}

// MARK: - private extension
private extension ViewController {
    
    func setup() {
        tableView.delegate = self
        tableView.dataSource = self
        collectionView.dataSource = self
        dateFormatter = DateFormatter()
    }
    
    func setBackground() {
        
        if let backgroundImage = UIImage.gif(name: "облачностьGif") {
            let backgroundImageView = UIImageView(image: backgroundImage)
            backgroundImageView.frame = self.view.bounds
            backgroundImageView.contentMode = .scaleAspectFill
            self.view.insertSubview(backgroundImageView, at: 0)
            self.view.backgroundColor = UIColor.clear
            self.scrollView.backgroundColor = UIColor.clear
        }
    }
}

// MARK: - checking for wi-fi connection + upload data from API + upload data from CoreData
extension ViewController {
    
    func checkForConnection() {
        if reachability.connection == .wifi {
            isConnected = true
            print("Connection good")
            refreshArrays()
            uploadInfo()
        } else {
            isConnected = false
            print("Connection bad")
            uploadDate()
            uploadTableViewArrays()
            uploadCollectionViewArrays()
        }
    }
}

// MARK: - parsing all info + refresh arrays
private extension ViewController {
    func refreshArrays() {
        namesOfDaysWeekArray.removeAll(keepingCapacity: false)
        forecastMinTempADayArray.removeAll(keepingCapacity: false)
        forecastMaxTempADayArray.removeAll(keepingCapacity: false)
        collectionHoursArray.removeAll(keepingCapacity: false)
        collectionCharacteristicWeahter.removeAll(keepingCapacity: false)
    }

    func uploadInfo() {
        let url = URL(string: "https://api.weatherapi.com/v1/forecast.json?key=ae85acc7d8bf42169ac123120230511&q=Novosibirsk&days=7&lang=ru")

        let session = URLSession.shared

        let task = session.dataTask(with: url!) { data, response, error in
            if error != nil {
                print(error?.localizedDescription ?? "error")
            } else {
                if data != nil {
                    do {
                        let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! Dictionary<String, Any>
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            deleteCoreData()
                            //geting info for top labels
                            self.fillTopLabels(jsonResponse)

                            //geting info for weather forecast for 6 days
                            self.dateFormatter.dateFormat = "yyyy-MM-dd"
                            self.currentTimeForForecast = self.dateFormatter.string(from: Date())

                            //adding to array days of week && min temp in a day
                            if let forecast = jsonResponse["forecast"] as? [String : Any] {
                                if let forecastDay = forecast["forecastday"] as? [[String : Any]] {
                                    for day in forecastDay {
                                        self.extractDate(day)
                                        self.extractTempForDay(day)
                                        self.extractHours(day)
                                    }
                                }
                            }
                            self.tableView.reloadData()
                            self.collectionView.reloadData()
                            saveDate()
                        }
                    } catch {
                        print("error1")
                    }
                } else {
                    print("data is empty")
                }
            }
        }
        task.resume()
    }
    
    private func extractHours(_ day : [String : Any]) {
        if let hourInfo = day["hour"] as? [[String : Any]] {
            for hourDate in hourInfo {
                if let time = hourDate["time"] as? String {
                    if let temp = hourDate["temp_c"] as? Double {
                        if let condition = hourDate["condition"] as? [String : Any] {
                            if let text = condition["text"] as? String {
                                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

                                //getting hour from json and comparing with current hour && degrees
                                if let date = dateFormatter.date(from: time) {
                                    let calendar = Calendar.current
                                    let hour = calendar.component(.hour, from: date)
                                    let currentHour = calendar.component(.hour, from: Date())
                                    if calendar.isDate(date, inSameDayAs: Date()) && currentHour <= hour {

                                        //adding to array
                                        if currentHour == hour {
                                            collectionHoursArray.append("Сейчас")
                                            collectionDegreesArray.append(Int(temp))
                                            collectionCharacteristicWeahter.append(text)
                                        } else {
                                            collectionHoursArray.append(String(hour))
                                            collectionDegreesArray.append(Int(temp))
                                            collectionCharacteristicWeahter.append(text)
                                        }
                                    } else if calendar.isDate(date, inSameDayAs: Calendar.current.date(byAdding: .day, value: 1, to: Date())!) {
                                        collectionHoursArray.append(String(hour))
                                        collectionDegreesArray.append(Int(temp))
                                        collectionCharacteristicWeahter.append(text)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func extractDate(_ day: [String : Any]) {
        if var futureDate = day["date"] as? String {
            if futureDate == currentTimeForForecast {
                namesOfDaysWeekArray.append("Сегодня")
            } else {
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let displayingDate = dateFormatter.date(from: futureDate) ?? Date()
                dateFormatter.dateFormat = "EEEE"
                let changeToDayWeek = dateFormatter.string(from: displayingDate)
                futureDate = changeToDayWeek.capitalized
                namesOfDaysWeekArray.append(futureDate)
            }
        }
    }

    private func extractTempForDay(_ day: [String : Any]) {
        if let futureTempCast = day["day"] as? [String : Any] {
            if let futureWeather = futureTempCast["condition"] as? [String : Any] {
                if let futureMinTemp = futureTempCast["mintemp_c"] as? Double {
                    forecastMinTempADayArray.append(Int(futureMinTemp))
                }
                if let futureMaxTemp = futureTempCast["maxtemp_c"] as? Double {
                    forecastMaxTempADayArray.append(Int(futureMaxTemp))
                }
                if let text = futureWeather["text"] as? String {
                    forecastWeatherForDayArray.append(text)
                }
            }
        }
    }
    
    private func fillTopLabels(_ jsonResponse: Dictionary<String, Any>) {
        if let cityResponse = jsonResponse["location"] as? [String : Any] {
            if let city = cityResponse["name"] as? String {
                cityLabel.text = city.localizedCapitalized
            }
        }
        if let currentWeather = jsonResponse["current"] as? [String : Any] {
            if let tempADay = currentWeather["temp_c"] as? Int {
                degreesLabel.text = "\(tempADay)°"
            }
            if let currentCondition = currentWeather["condition"] as? [String : Any] {
                if let characteristicText = currentCondition["text"] as? String {
                    characteristicLabel.text = characteristicText
                }
            }
            if let feelsLike = currentWeather["feelslike_c"] as? Double {
                feelsLikeLabel.text = "Ощущается как \(Int(feelsLike))"
            }
        }
    }
}

// MARK: - Save to CoreData (cash) + output CoreData + delete CoreData
private extension ViewController {
 
    func saveDate() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let cashMainInfo = NSEntityDescription.insertNewObject(forEntityName: "CashData", into: context)

        cashMainInfo.setValue(cityLabel.text, forKey: "cityName")
        cashMainInfo.setValue(degreesLabel.text, forKey: "nowDegree")
        cashMainInfo.setValue(characteristicLabel.text, forKey: "characteristicWeather")
        cashMainInfo.setValue(feelsLikeLabel.text, forKey: "feelLike")
        
        do {
            try context.save()
            print("success to save top labels")
        } catch {
            print("can't save top labels")
        }
    }

    func deleteCoreData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CashData")
        
        do {
            let results = try context.fetch(fetchRequest)
            for result in results as! [NSManagedObject] {
                context.delete(result)
                
                do {
                    try context.save()
                } catch {
                    
                }
            }
        } catch {
            print("can't delete data")
        }
    }
}

// MARK: - upload from CoreData
extension ViewController {
    
    func uploadDate() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CashData")
        
        do {
            let results = try context.fetch(fetchRequest)
            for result in results as! [NSManagedObject] {
               uploadDataForTopLabels(result: result)
            }
        } catch {
            print("can't upload data to top labels")
        }
        tableView.reloadData()
    }
 
    
    func uploadTableViewArrays() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CashData")
        fetchRequest.predicate = NSPredicate(format: "day != nil && minTemp != nil && maxTemp != nil && weatherTableView != nil")
        
        do {
            let results = try context.fetch(fetchRequest)
            
            for data in results as! [NSManagedObject] {
                uploadDataForTableView(data: data)
            }
        } catch {
            print("can't upload tableView")
        }
        tableView.reloadData()
    }
    
    func uploadCollectionViewArrays() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CashData")
        fetchRequest.predicate = NSPredicate(format: "collectionHour != nil && collectionWeather != nil && collectionDegree != nil")
        do {
            let results = try context.fetch(fetchRequest)
            
            for data in results as! [NSManagedObject] {
                uploadDataForColletionView(data: data)
            }
        } catch {
            print("can't upload collectionView")
        }
        collectionView.reloadData()
    }
    
    private func uploadDataForTopLabels(result : NSManagedObject) {
        if let cityName = result.value(forKey: "cityName") as? String {
            cityLabel.text = cityName
        }
        if let degree = result.value(forKey: "nowDegree") as? String {
            degreesLabel.text = degree
        }
        if let characteristic = result.value(forKey: "characteristicWeather") as? String {
            characteristicLabel.text = characteristic
        }
        if let feelLike = result.value(forKey: "feelLike") as? String {
            feelsLikeLabel.text = feelLike
        }
    }
    
    private func uploadDataForTableView(data : NSManagedObject) {
        if let day  = data.value(forKey: "day") as? String {
            namesOfDaysWeekArray.append(day)
        }
        if let minTemp = data.value(forKey: "minTemp") as? Int {
            forecastMinTempADayArray.append(minTemp)
        }
        if let maxTemp = data.value(forKey: "maxTemp") as? Int {
            forecastMaxTempADayArray.append(maxTemp)
        }
        if let weather = data.value(forKey: "weatherTableView") as? String {
            forecastWeatherForDayArray.append(weather)
        }
    }

    private func uploadDataForColletionView(data : NSManagedObject) {
        if let hour  = data.value(forKey: "collectionHour") as? String {
            collectionHoursArray.append(hour)
        }
        if let weather = data.value(forKey: "collectionWeather") as? String {
            collectionCharacteristicWeahter.append(weather)
        }
        if let degree = data.value(forKey: "collectionDegree") as? Int {
            collectionDegreesArray.append(degree)
        }
    }
}

// MARK: - ViewController + UITableViewDataSource
extension ViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isConnected {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cellPrototype", for: indexPath) as! cellPrototype
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let cashDays = NSEntityDescription.insertNewObject(forEntityName: "CashData", into: context)
            
            uploadTableViewCells(cell: cell, indexPath: indexPath)
            
            cell.backgroundColor = .clear

            if namesOfDaysWeekArray.count > indexPath.row && forecastMinTempADayArray.count > indexPath.row && forecastMaxTempADayArray.count > indexPath.row && forecastWeatherForDayArray.count > indexPath.row {
                saveTableViewCellsToCoreData(cashDays: cashDays, indexPath: indexPath)
            }

            do {
                try context.save()
                print("Данные TableView успешно сохранены в Core Data")
            } catch {
                print("Ошибка сохранения данных TableView в Core Data: \(error)")
            }

            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cellPrototype", for: indexPath) as! cellPrototype
            uploadTableViewCells(cell: cell, indexPath: indexPath)
            cell.backgroundColor = .clear
            
            return cell
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return namesOfDaysWeekArray.count
    }
    
    private func uploadTableViewCells(cell : cellPrototype, indexPath : IndexPath) {
        if namesOfDaysWeekArray.count > 0 {
            cell.dayOfWeekLabel.text = namesOfDaysWeekArray[indexPath.row]
        }
        if forecastMinTempADayArray.count > 0 {
            cell.minTempLabel.text = "Min: \(forecastMinTempADayArray[indexPath.row])"
        }
        if forecastMaxTempADayArray.count > 0 {
            cell.maxTempLabel.text = "Max: \(forecastMaxTempADayArray[indexPath.row])"
        }
        if forecastWeatherForDayArray.count > 0 {
            cell.weatherImage.image = getImageByState(forecastWeatherForDayArray[indexPath.row])
        }
    }
    
    private func saveTableViewCellsToCoreData(cashDays : NSManagedObject, indexPath : IndexPath) {
        cashDays.setValue(namesOfDaysWeekArray[indexPath.row], forKey: "day")
        cashDays.setValue(forecastMinTempADayArray[indexPath.row], forKey: "minTemp")
        cashDays.setValue(forecastMaxTempADayArray[indexPath.row], forKey: "maxTemp")
        cashDays.setValue(forecastWeatherForDayArray[indexPath.row], forKey: "weatherTableView")
    }
}

// MARK: - ViewController + UITableViewDelegate
extension ViewController : UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if numberOfSections(in: tableView) == 1 {
            return 48
        }
        return 100
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return LocalizedStrings.weatherForecastNextSixDays
    }
}

// MARK: - ViewController + UICollectionDataSource
extension ViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 24
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if isConnected {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "postCell", for: indexPath) as! PostCellCollectionViewCell
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let cashDays = NSEntityDescription.insertNewObject(forEntityName: "CashData", into: context)

            uploadCollectionViewLabels(cell: cell, indexPath: indexPath)

            if collectionHoursArray.count > indexPath.row && collectionCharacteristicWeahter.count > indexPath.row && collectionDegreesArray.count > indexPath.row{
                saveCollectionViewLabelToCoreData(cashDays: cashDays, indexPath: indexPath)
            }
            
            do {
                try context.save()
                print("Данные CollectionView успешно сохранены в Core Data")
            } catch {
                print("Ошибка сохранения данных CollectionView в Core Data: \(error)")
            }
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "postCell", for: indexPath) as! PostCellCollectionViewCell
            uploadCollectionViewLabels(cell: cell, indexPath: indexPath)
            return cell
        }
    }

    private func uploadCollectionViewLabels(cell : PostCellCollectionViewCell, indexPath : IndexPath) {
        if collectionHoursArray.count > 0 {
            cell.timeLabel.text = collectionHoursArray[indexPath.row]
        }
        
        if collectionDegreesArray.count > 0 {
            cell.degreeLabel.text = String(collectionDegreesArray[indexPath.row])
        }
        
        if collectionCharacteristicWeahter.count > 0 {
            cell.imageWeather.image = getImageByState(collectionCharacteristicWeahter[indexPath.row])
        }
    }
    
    private func saveCollectionViewLabelToCoreData(cashDays : NSManagedObject, indexPath : IndexPath) {
        cashDays.setValue(collectionHoursArray[indexPath.row], forKey: "collectionHour")
        cashDays.setValue(collectionCharacteristicWeahter[indexPath.row], forKey: "collectionWeather")
        cashDays.setValue(collectionDegreesArray[indexPath.row], forKey: "collectionDegree")
    }
}

// MARK: - customizing tableView + collectionView
private extension ViewController {

    func customTableView() {
        tableView.backgroundColor = .clear
    }

    func customCollectionView() {
        collectionView.backgroundColor = .clear
    }
}

// MARK: - upload images to tableView + collectionView
extension ViewController {
    
    private func getImageByState(_ characteristicWeather: String) -> UIImage? {
        switch characteristicWeather {
        case WeatherType.cloudsSometimes.rawValue:
            return ImageResources.mightBeCloudyAtNight
        case WeatherType.littleSnow.rawValue:
            return ImageResources.littleSnow
        case WeatherType.littleColdRain.rawValue:
            return ImageResources.littleColdRain
        case WeatherType.littleDark.rawValue:
            return ImageResources.littleDark
        case WeatherType.cloudy.rawValue:
            return ImageResources.cloudy
        case WeatherType.littleRainWithSnow.rawValue:
            return ImageResources.littleRainWithSnow
        case WeatherType.sometimesSnow.rawValue:
            return ImageResources.sometimesSnow
        case WeatherType.fog.rawValue:
            return ImageResources.fog
        case WeatherType.coldFog.rawValue:
            return ImageResources.coldFog
        case WeatherType.sunny.rawValue:
            return ImageResources.sunny
        case WeatherType.clear.rawValue:
            return ImageResources.clear
        case WeatherType.sometimesRain.rawValue:
            return ImageResources.sometimesRain
        case WeatherType.strongSnow.rawValue:
            return ImageResources.strongSnow
        case WeatherType.veryStrongSnow.rawValue:
            return ImageResources.veryStrongSnow
        case WeatherType.averageSnow.rawValue:
            return ImageResources.averageSnow
        default:
            return UIImage()
        }
    }
}
