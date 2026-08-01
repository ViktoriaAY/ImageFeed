import UIKit
 
final class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        print("[TabBarCtrl]: 1. Метод viewDidLoad успешно запущен")
       
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        
        print("[TabBarCtrl]: 2. Безопасно загружаем ImagesListViewController...")
        
        let imagesListViewController = storyboard.instantiateViewController(
            withIdentifier: "ImagesListViewController"
        ) as! ImagesListViewController
            
        print("[TabBarCtrl]: 3. Создаем ProfileViewController...")
        
        let profileViewController = ProfileViewController()
        
        print("[TabBarCtrl]: 4. Настраиваем иконки вкладок...")
        imagesListViewController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(named: "tab_editorial_active"),
            selectedImage: nil
        )
        
        profileViewController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(named: "tab_profile_active"),
            selectedImage: nil
        )
           
        print("[TabBarCtrl]: 5. Передаем контроллеры в системный массив таббара...")
        self.viewControllers = [imagesListViewController, profileViewController]
        print("[TabBarCtrl]: 6. Настройка таббара успешно завершена! Экраны должны отобразиться.")
    }
}
