//
//  MoedasViewController.swift
//  ProjetoFinalSquad3
//
//  Created by Adalberto Sena Silva on 15/04/21.
//

import UIKit
import Commons
import AlamofireImage
import DetalhesMoedas
import CoreData


class MoedasViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    
     // MARK: - Outlets
    
    @IBOutlet weak var listaMoedas: UITableView!
    
    // MARK: - Selecao de Atributos da Classe

    var listaDeMoedas:[Criptomoeda] = []
    
    var listaSiglasFavoritas: [String] = []
    
    var contexto: NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    var gerenciadorDeResultados:NSFetchedResultsController<Favoritos>?
    

    
    // MARK: - Ciclo de Vida
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.listaMoedas.register(UINib(nibName: "CustumTableViewCell", bundle: nil), forCellReuseIdentifier: "CustumTableViewCell")
        self.listaMoedas.delegate = self
        self.listaMoedas.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        makeRequest{ (_) in
            DispatchQueue.main.async {
                self.listaMoedas.reloadData()
            }
        }
    }
    
    // MARK: - TableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.listaDeMoedas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustumTableViewCell", for: indexPath) as! CustumTableViewCell
        let moedaAtual = listaDeMoedas[indexPath.row]
        guard let gerenciador = gerenciadorDeResultados?.fetchedObjects else {return cell}
        if gerenciador.count > 0 {
            for i in 0...(((gerenciadorDeResultados?.fetchedObjects!.count)!) - 1) {
                guard let sigla = gerenciador[i].lista else {return cell}
                listaSiglasFavoritas.append(sigla)
            }
        }
        cell.configuraCelula(listaSiglasFavoritas, moedaAtual)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let moedaSelecionada = listaDeMoedas[indexPath.item]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "detalhesMoedaSelecionada") as! DetalhesViewController
        controller.moedaSelecionada = moedaSelecionada
        show(controller, sender: self)
        //self.navigationController?.pushViewController(controller, animated: true)
    }

    
    // MARK: - Request
    
    func makeRequest(completion:@escaping([Criptomoeda]) -> Void) {
        let url = URL(string: ApiRest.TodasAsMoedas)!
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                print(response as Any)
                guard let responseData = data else { return }
                do {
                    let moedas = try JSONDecoder().decode(Moedas.self, from: responseData)
                    for i in 0...5 {
                        var moedaFiltrada = moedas.filter {$0.typeIsCrypto == 1 && $0.priceUsd ?? 0>0 && (($0.idIcon?.isEmpty) != nil)}
                        guard let sigla = moedaFiltrada[i].assetID else {return}
                        guard let nome = moedaFiltrada[i].name else {return}
                        guard let valor = moedaFiltrada[i].priceUsd else {return}
                        guard let idIcon = moedaFiltrada[i].idIcon else {return}
                        let criptomoeda = Criptomoeda(sigla: sigla, nome: nome, valor: valor, imagem: idIcon)
                        self.listaDeMoedas.append(criptomoeda)
                     }
                    completion(self.listaDeMoedas)
                } catch let error {
                    print("error: \(error)")
                }
            }
        task.resume()
    }
    
    
    // MARK: - Fun????es
    
    func recuperaFavoritos() {
        let recuperaFavoritos: NSFetchRequest<Favoritos> = Favoritos.fetchRequest()
        let ordenaPorNome = NSSortDescriptor(key: "lista", ascending: true)
        recuperaFavoritos.sortDescriptors = [ordenaPorNome]
        gerenciadorDeResultados = NSFetchedResultsController(fetchRequest: recuperaFavoritos, managedObjectContext: contexto, sectionNameKeyPath: nil, cacheName: nil)
        gerenciadorDeResultados?.delegate = self
        do {
            try gerenciadorDeResultados?.performFetch()
        } catch {
            print(error.localizedDescription)
        }
    }
}
