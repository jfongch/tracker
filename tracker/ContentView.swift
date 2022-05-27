//
//  ContentView.swift
//  tracker
//
//  Created by Jeremy Fong on 5/11/22.
//

import SwiftUI
import CoreData


struct ContentView: View {
    @State private var showingWizard = false

    var body: some View {
        NavigationView {
            if showingWizard {
                ZStack(alignment: .bottom) {
                    WizardView()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: toggleShowingWizard) {
                            Text("Cancel")
                                .foregroundColor(Color.red)
                        }
                    }
                }
            } else {
                ZStack(alignment: .bottom) {
                    HomeScreenView()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: toggleShowingWizard) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
            }
        }
    }
    
    private func toggleShowingWizard() {
        showingWizard = !showingWizard
    }
    
}


struct WizardView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State var name: String = ""
    @State var startDate: Date = Date()

    var body: some View {
        Form {
            Section(header: Text("PROFILE")) {
                TextField("What're we tracking?", text: $name)
            }
            
            Section(header: Text("When did you start using this?")) {
                DatePicker("", selection: $startDate)
                    .datePickerStyle(GraphicalDatePickerStyle())
            }
            

        }
    }
}

struct HomeScreenView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.tracking?.estimatedEndDate, ascending: false)],
        animation: .default)
    private var items: FetchedResults<Item>
    @State var shouldShowSheet: Bool = false
    @State var itemToShow: Item?

    var body: some View {
        List {
            ForEach(items) { item in
                Button(item.name!) {
                    itemToShow = item
                    shouldShowSheet = true
//                    Text(item.icon ?? "🐣")
//                    Text(item.name ?? "New Item")
//                    Text(getItemTypeString(item: item))
//                    Text("Item size is \(item.itemSize?.amount ?? 1) \(item.itemSize?.sizeUnit ?? "L")")
//
//                    if (item.tracking?.estimatedEndDate != nil) {
//                        Text("There are \(numberOfDaysBetween(Date(), and: (item.tracking?.estimatedEndDate)!)) \(item.tracking?.timeUnit ?? "days") remaining")
//                    } else {
//                        Text("You started using this item on \(item.tracking?.startDate ?? Date(), formatter: itemFormatter)")
//                    }
//                } label: {
//                    Text("\(item.name!), 1 day remaining")
//                }
//                .onTapGesture {
//                    itemToShow = item
//                    shouldShowSheet = true
                }
            }
            .onDelete(perform: deleteItems)
        }
        if (itemToShow != nil) {
            OverviewSheetView(item: itemToShow, onDismiss: dismissSheet)
        }
    }
    
    private func dismissSheet() {
        shouldShowSheet = false
        itemToShow = nil
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.id = UUID()
            newItem.name = "someItemName"
            newItem.timestamp = Date()
            newItem.icon = "🧻"
            newItem.purchaseUrl = URL(string: "https://buyhere.com")
            newItem.sku = "000000000010101"
            
            let size = Size(context: viewContext)
            size.amount = 1
            size.sizeUnit = "L"
            newItem.itemSize = size
            
            let tracking = Tracking(context: viewContext)
            tracking.startDate = Date()
            tracking.expiryDate = Date() + 2
            newItem.tracking = tracking

            let type = Type(context: viewContext)
            type.itemClass = "Food"
            newItem.itemType = type
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
        
}

struct OverviewSheetView: View {
    var item: Item?
    var onDismiss: () -> Void
    @State private var offsets = (middle: CGFloat.zero, bottom: CGFloat.zero)
    @State private var offset: CGFloat = .greatestFiniteMagnitude
    @State private var lastOffset: CGFloat = .greatestFiniteMagnitude
    
    var body: some View {
        if item != nil {
            GeometryReader { geometry in
                VStack {
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundColor(.gray)
                        .frame(width: 100, height: 10)
                    Text(item!.name!)
                        .font(.largeTitle)
                    Text(item!.icon ?? "🐣")
                    Text(getItemTypeString(item: item!))
                    Text("Item size is \(item!.itemSize?.amount ?? 1) \(item!.itemSize?.sizeUnit ?? "L")")

                    if (item!.tracking?.estimatedEndDate != nil) {
                        Text("There are \(numberOfDaysBetween(Date(), and: (item!.tracking?.estimatedEndDate)!)) \(item!.tracking?.timeUnit ?? "days") remaining")
                    } else {
                        Text("You started using this item on \(item!.tracking?.startDate ?? Date(), formatter: itemFormatter)")
                    }
                    Spacer()
                }
                .padding()
                .frame(width: geometry.size.width, height: self.offset)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: min(self.offset, 20) ))
                .animation(Animation.interactiveSpring())
                .onAppear {
                    self.offsets = (
                        middle: geometry.size.height / 2,
                        bottom: geometry.size.height * 3 / 4
                    )
                    self.offset = geometry.size.height * 3 / 4
                    self.lastOffset = self.offset
                }
                .offset(y: self.offset)
                .gesture(DragGesture(minimumDistance: 5)
                    .onChanged { v in
                        let newOffset = self.lastOffset + v.translation.height
                        if (newOffset > self.offsets.middle) {
                            self.offset = newOffset
                        }
                    }
                    .onEnded{ v in
                        if (self.lastOffset == self.offsets.middle) {
                            if (v.translation.height < 0) {
                                self.offset = self.offsets.middle
                            } else {
                                self.offset = self.offsets.bottom
                            }
                        } else {
                            if (v.translation.height > 0) {
                                onDismiss()
                            } else {
                                self.offset = self.offsets.middle
                            }
                        }
                        self.lastOffset = self.offset
                    }
                )
            }
            .edgesIgnoringSafeArea(.all)
        }
    }

    private func getItemTypeString(item: Item) -> String {
        let subclassString: String = item.itemType?.itemSubclass?.isEmpty ?? true ? "" : " - \(String(describing: item.itemType?.itemSubclass))"
        
        return "\(String(describing: item.itemType?.itemClass))\(subclassString)"
    }

}

private func numberOfDaysBetween(_ from: Date, and to: Date) -> Int {
    let calendar = Calendar.current
    let date1 = calendar.startOfDay(for: from)
    let date2 = calendar.startOfDay(for: to)

    let numberOfDays = calendar.dateComponents([.day], from: date1, to: date2)
    
    return numberOfDays.day!
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
