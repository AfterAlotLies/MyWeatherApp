//
//  ViewController.swift
//  myWeatherApp
//
//  Created by Vyacheslav on 30.10.2023.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDelegate {

    //topLabels
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var degreesLabel: UILabel!
    @IBOutlet weak var characteristicLabel: UILabel!
    @IBOutlet weak var feelsLikeLabel: UILabel!

    //tableView + collectionView
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    //arrays for tableView
    var namesOfDaysWeekArray = [String]()
    var forecastMinTempADayArray = [Int]()
    var forecastMaxTempADayArray = [Int]()

    //arrays for collectionView
    var collectionHoursArray = [String]()
    var collectionDegreesArray = [Int]()
    var collectionCharacteristicWeahter = [String]()

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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshArrays()
        uploadInfo()
        customTableView()
        customCollectionView()
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
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    func setBackground() {
        //        let charactersiticLabel = characteristicLabel.text
        //
        //        switch charactersiticLabel {
        //        case "Переменная облачность":
        if let backgroundImage = UIImage.gif(name: "backgroundGif") {
            let backgroundImageView = UIImageView(image: backgroundImage)
            backgroundImageView.frame = self.view.bounds
            backgroundImageView.contentMode = .scaleAspectFill
            self.view.insertSubview(backgroundImageView, at: 0)
            self.view.backgroundColor = UIColor.clear
            self.scrollView.backgroundColor = UIColor.clear
            
            //            }
            //        default:
            //            print("error")
            //        }
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
        let url = URL(string: "https://api.weatherapi.com/v1/forecast.json?key=53767b8f6af94b368e6122737233110&q=Novosibirsk&days=7&lang=ru")

        let session = URLSession.shared

        let task = session.dataTask(with: url!) { data, response, error in
            if error != nil {
                let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: UIAlertController.Style.alert)
                let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
                alert.addAction(okButton)
                self.present(alert, animated: true)
            } else {
                if data != nil {
                    do {
                        let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! Dictionary<String, Any>
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            //geting info for top labels
                            self.fillTopLabels(jsonResponse)

                            //geting info for weather forecast for 6 days
                            let dateChecking = DateFormatter()
                            dateChecking.dateFormat = "yyyy-MM-dd"
                            let currentTimeForForecast = dateChecking.string(from: Date())

                            //adding to array days of week && min temp in a day
                            if let forecast = jsonResponse["forecast"] as? [String : Any] {
                                if let forecastDay = forecast["forecastday"] as? [[String : Any]] {
                                    for day in forecastDay {
                                        if var futureDate = day["date"] as? String {
                                            if futureDate == currentTimeForForecast {
                                                self.namesOfDaysWeekArray.append("Сегодня")
                                            } else {
                                                let dateConvertor = DateFormatter()
                                                dateConvertor.dateFormat = "EEEE"
                                                let changeToDayWeek = dateConvertor.string(from: dateChecking.date(from: futureDate)!)
                                                futureDate = changeToDayWeek.capitalized
                                                self.namesOfDaysWeekArray.append(futureDate)
                                            }
                                        }
                                        if let futureTempCast = day["day"] as? [String : Any] {
                                            if let futureMinTemp = futureTempCast["mintemp_c"] as? Double {
                                                self.forecastMinTempADayArray.append(Int(futureMinTemp))
                                            }
                                            if let futureMaxTemp = futureTempCast["maxtemp_c"] as? Double {
                                                self.forecastMaxTempADayArray.append(Int(futureMaxTemp))
                                            }
                                        }

                                        //adding to array all hours for the current day && degrees
                                        if let hourInfo = day["hour"] as? [[String : Any]] {
                                            for hourDate in hourInfo {
                                                if let time = hourDate["time"] as? String {
                                                    if let temp = hourDate["temp_c"] as? Double {
                                                        if let condition = hourDate["condition"] as? [String : Any] {
                                                            if let text = condition["text"] as? String {
                                                                let dateConvertor = DateFormatter()
                                                                dateConvertor.dateFormat = "yyyy-MM-dd HH:mm"

                                                                //getting hour from json and comparing with current hour && degrees
                                                                if let date = dateConvertor.date(from: time) {
                                                                    let calendar = Calendar.current
                                                                    let hour = calendar.component(.hour, from: date)
                                                                    let currentHour = calendar.component(.hour, from: Date())
                                                                    if calendar.isDate(date, inSameDayAs: Date()) && currentHour <= hour {

                                                                        //adding to array
                                                                        if currentHour == hour {
                                                                            self.collectionHoursArray.append("Сейчас")
                                                                            self.collectionDegreesArray.append(Int(temp))
                                                                            self.collectionCharacteristicWeahter.append(text)
                                                                        } else {
                                                                            self.collectionHoursArray.append(String(hour))
                                                                            self.collectionDegreesArray.append(Int(temp))
                                                                            self.collectionCharacteristicWeahter.append(text)
                                                                        }
                                                                    } else if calendar.isDate(date, inSameDayAs: Calendar.current.date(byAdding: .day, value: 1, to: Date())!) {
                                                                        self.collectionHoursArray.append(String(hour))
                                                                        self.collectionDegreesArray.append(Int(temp))
                                                                        self.collectionCharacteristicWeahter.append(text)
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            self.tableView.reloadData()
                            self.collectionView.reloadData()
                        }
                    } catch {
                        print("error1")
                    }
                }
            }
        }
        task.resume()
    }
    
    private func fillTopLabels(_ jsonResponse: Dictionary<String, Any>) {
        if let cityResponse = jsonResponse["location"] as? [String : Any] {
            if let city = cityResponse["name"] as? String {
                self.cityLabel.text = city.localizedCapitalized
            }
        }
        if let currentWeather = jsonResponse["current"] as? [String : Any] {
            if let tempADay = currentWeather["temp_c"] as? Int {
                self.degreesLabel.text = "\(tempADay)°"
            }
            if let currentCondition = currentWeather["condition"] as? [String : Any] {
                if let characteristicText = currentCondition["text"] as? String {
                    self.characteristicLabel.text = characteristicText
                }
            }
            if let feelsLike = currentWeather["feelslike_c"] as? Double {
                self.feelsLikeLabel.text = "Ощущается как \(Int(feelsLike))"
            }
        }
    }
}

// MARK: - ViewController + UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        var context = cell.defaultContentConfiguration()
        context.text = namesOfDaysWeekArray[indexPath.row] + "| Мин.темп: \(forecastMinTempADayArray[indexPath.row])" + " | Макс.темп: \(forecastMaxTempADayArray[indexPath.row])"
        cell.contentConfiguration = context
        cell.backgroundColor = .clear
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return namesOfDaysWeekArray.count
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "postCell", for: indexPath) as! PostCellCollectionViewCell
        if collectionHoursArray.count > 0 {
            cell.timeLabel.text = collectionHoursArray[indexPath.row]
        }

        if collectionDegreesArray.count > 0 {
            cell.degreeLabel.text = String(collectionDegreesArray[indexPath.row])
        }
        
        if collectionCharacteristicWeahter.count > 0 {
            cell.imageWeather.image = getImageByState(collectionCharacteristicWeahter[indexPath.row])
        }
        return cell
    }
    
    private func getImageByState(_ characteristicWeather: String) -> UIImage? {
        switch characteristicWeather {
        case WeatherType.cloudsSometimes.rawValue:
            return ImageResources.mightBeCloudyAtNight
        case WeatherType.littleSnow.rawValue:
            return UIImage(named: "ПеременнаяОблачностьНочь")
        case WeatherType.littleColdRain.rawValue:
            return UIImage(named: "СлабыйПереохлажденныйДождьНочь")
        case WeatherType.littleDark.rawValue:
            return UIImage(named: "ПасмурноНочь")
        case WeatherType.cloudy.rawValue:
            return UIImage(named: "ОблачноНочь")
        case WeatherType.littleRainWithSnow.rawValue:
            return UIImage(named: "НебольшойДождьСоСнегомНочь")
        case WeatherType.sometimesSnow.rawValue:
            return UIImage(named: "НебольшойДождьСоСнегомНочь")
        case WeatherType.fog.rawValue:
            return UIImage(named: "ДымкаНочь")
        case WeatherType.coldFog.rawValue:
            return UIImage(named: "ПереохлажденныйТуманНочь")
        case WeatherType.sunny.rawValue:
            return UIImage(named: "СолнечноНочь")
        case WeatherType.clear.rawValue:
            return UIImage(named: "СолнечноНочь")
        case WeatherType.sometimesRain.rawValue:
            return UIImage(named: "МестамиДождьНочь")
        default:
            return UIImage()
        }
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
