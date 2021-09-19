import Foundation
import CGtk
import Gdk
import Gtk
import GLibObject

var window: ApplicationWindow!
var store: ListStore!
var hd: HeaderBar!
var b_back, b_calc: Button!
var entry_page: EntryPage!
var result_page: ResultPage!
var appActionEntries = [
    GActionEntry(name: g_strdup("quit"), activate: { Gtk.ApplicationRef(gpointer: $2).quit() }, parameter_type: nil, state: nil, change_state: nil, padding: (0, 0, 0))
]

class MyScale<E: CaseIterable & RawRepresentable> where E.RawValue == String {
    private(set) var wdg: Grid
    private var scale: Scale
    private var label: Label
    private var val_to_name: Dictionary<Int, String>

    init() {
        val_to_name = Dictionary()
        wdg = Grid()
        scale = Scale(range: .horizontal ,min: 0, max: Double(E.allCases.count), step: 1)
        for (idx, val) in E.allCases.enumerated() {    
            if idx == 0 || idx == E.allCases.count - 1 {
                scale.addMark(value: Double(idx), position: GtkPositionType.top, markup: val.rawValue)
            }
            else {
                scale.addMark(value: Double(idx), position: GtkPositionType.top)
            }

            val_to_name[idx] = val.rawValue
        }
        scale.drawValue = false
        scale.hexpand = true
        scale.roundDigits = 0

        label = Label(text: "")

        scale.connect(signal: ScaleSignalName.stateChanged, handler: {
            self.label.text = self.val_to_name[Int(self.scale.value)]
        })

        
        wdg.add(scale)
        wdg.add(label)
    }
}

class InfoButton {
    var wdg: Button
    var popover: Popover
    var l_popover: Label

    init(msg: String) {
        wdg = Button(label: "Info")
        
        popover = Popover(relativeTo: wdg)

        l_popover = Label(text: msg)   
        popover.add(l_popover) 
        
        wdg.styleContext.addClass(className:"plain")
        wdg.connect(signal: ButtonSignalName.clicked, handler: {
            self.popover.showAll()
        })
    }
}

class EntryPage {
    var wdg: Grid

    var r_man, r_woman, r_goal_stable, r_goal_up, r_goal_down: RadioButton
    var l_total_weight, l_fat_percent, l_sex, l_activity, l_goal: Label
    var e_total_kg,e_fat_percent: Entry
    var s_activity: MyScale<Activity>, s_goal_intensity: MyScale<GoalIntensity>
    var b_info_fat: InfoButton

    init() {
        wdg = Grid()
        wdg.orientation = .vertical

        l_total_weight = Label(text: "Weight:")
        wdg.attach(child: l_total_weight, left: 0, top: 0, width: 1, height: 1)
        
        e_total_kg = Entry()
        e_total_kg.placeholderText = "Kg"
        wdg.attach(child: e_total_kg, left: 1, top: 0, width: 2, height: 1)

        l_fat_percent = Label(text: "%Fat:")
        wdg.attach(child: l_fat_percent, left: 0, top: 1, width: 1, height: 1)

        e_fat_percent = Entry()
        e_fat_percent.placeholderText = "% (Optional)"
        wdg.attach(child: e_fat_percent, left: 1, top: 1, width: 2, height: 1)

        b_info_fat = InfoButton(msg: "This field is optional. Having it means we can provide more accurate information, but it's not mandatory.")
        wdg.attach(child: b_info_fat.wdg, left: 2, top: 1, width: 3, height: 1)

        l_sex = Label(text: "Sex:")
        wdg.attach(child: l_sex, left: 0, top: 2, width: 1, height: 1)

        r_man = RadioButton(label: "Man")
        r_woman = RadioButton(group: r_man.group, label: "Woman")

        wdg.attach(child: r_man, left: 1, top: 2, width: 1, height: 1)
        wdg.attach(child: r_woman, left: 2, top: 2, width: 1, height: 1)

        l_activity = Label(text: "Activity:")
        wdg.attach(child: l_activity, left: 0, top: 3, width: 1, height: 1)

        s_activity = MyScale()
        wdg.attach(child:s_activity.wdg, left: 1, top: 3, width: 2, height: 1)

        l_goal = Label(text: "Goal:")
        wdg.attach(child: l_goal, left: 0, top: 4, width: 1, height: 1)

        r_goal_stable = RadioButton(label: "Stable")
        r_goal_up = RadioButton(group: r_goal_stable.group, label: "Up")
        r_goal_down = RadioButton(group: r_goal_stable.group, label: "Down")

        wdg.attach(child: r_goal_stable, left: 1, top: 4, width: 1, height: 1)
        wdg.attach(child: r_goal_up, left: 2, top: 4, width: 1, height: 1)
        wdg.attach(child: r_goal_down, left: 3, top: 4, width: 1, height: 1)

        s_goal_intensity = MyScale()
        wdg.attach(child:s_goal_intensity.wdg, left: 4, top: 4, width: 2, height: 1)

        b_calc = Button(label: "Calculate")
        b_calc.styleContext.addClass(className:"suggested-action")
        b_calc.sensitive = false
        wdg.add(b_calc)

        /*e_total_kg.connect(signal: EntrySignalName.stateChanged, handler: {
            b_calc.sensitive =  self.e_total_kg.text.count > 0
        })*/


    }

    func hide(){
        wdg.hide()
    }

    func show(){
        wdg.show()
    }

    func on_calc(handler: @escaping GLibObject.SignalHandler) {
        b_calc.connect(signal: .clicked, handler: handler)
    }
}

struct ResultPage {
    var wdg: Grid
    var l_calories, l_calories_min, l_calories_min_v, l_calories_max, l_calories_max_v: Label
    var l_proteins, l_proteins_min, l_proteins_min_v, l_proteins_max, l_proteins_max_v: Label
    var l_fats, l_fats_min, l_fats_min_v, l_fats_max, l_fats_max_v: Label
    var l_carbs, l_carbs_min, l_carbs_min_v, l_carbs_max, l_carbs_max_v: Label

    init() {
        wdg = Grid()
        wdg.orientation = .vertical

        l_calories = Label(text: "Calories:")
        l_calories_min = Label(text: "↓")
        l_calories_min_v = Label(text: "0.0")
        l_calories_max = Label(text: "↑")
        l_calories_max_v = Label(text: "0.0")
        
        wdg.attach(child: l_calories, left: 0, top: 0, width: 1, height: 1)
        wdg.attach(child: l_calories_min, left: 1, top: 0, width: 1, height: 1)
        wdg.attach(child: l_calories_min_v, left: 2, top: 0, width: 1, height: 1)
        wdg.attach(child: l_calories_max, left: 3, top: 0, width: 1, height: 1)
        wdg.attach(child: l_calories_max_v, left: 4, top: 0, width: 1, height: 1)

        l_proteins = Label(text: "Proteins:")
        l_proteins_min = Label(text: "↓")
        l_proteins_min_v = Label(text: "0.0")

        l_proteins_max = Label(text: "↑")
        l_proteins_max_v = Label(text: "0.0")

        wdg.attach(child: l_proteins, left: 0, top: 1, width: 1, height: 1)
        wdg.attach(child: l_proteins_min, left: 1, top: 1, width: 1, height: 1)
        wdg.attach(child: l_proteins_min_v, left: 2, top: 1, width: 1, height: 1)
        wdg.attach(child: l_proteins_max, left: 3, top: 1, width: 1, height: 1)
        wdg.attach(child: l_proteins_max_v, left: 4, top: 1, width: 1, height: 1)
        
        l_fats = Label(text: "Fats:")
        l_fats_min = Label(text: "↓")
        l_fats_min_v = Label(text: "0.0")

        l_fats_max = Label(text: "↑")
        l_fats_max_v = Label(text: "0.0")
        
        wdg.attach(child: l_fats, left: 0, top: 2, width: 1, height: 1)
        wdg.attach(child: l_fats_min, left: 1, top: 2, width: 1, height: 1)
        wdg.attach(child: l_fats_min_v, left: 2, top: 2, width: 1, height: 1)
        wdg.attach(child: l_fats_max, left: 3, top: 2, width: 1, height: 1)
        wdg.attach(child: l_fats_max_v, left: 4, top: 2, width: 1, height: 1)

        l_carbs = Label(text: "Carbs:")
        l_carbs_min = Label(text: "↓")
        l_carbs_min_v = Label(text: "0.0")

        l_carbs_max = Label(text: "↑")
        l_carbs_max_v = Label(text: "0.0")

        wdg.attach(child: l_carbs, left: 0, top: 3, width: 1, height: 1)
        wdg.attach(child: l_carbs_min, left: 1, top: 3, width: 1, height: 1)
        wdg.attach(child: l_carbs_min_v, left: 2, top: 3, width: 1, height: 1)
        wdg.attach(child: l_carbs_max, left: 3, top: 3, width: 1, height: 1)
        wdg.attach(child: l_carbs_max_v, left: 4, top: 3, width: 1, height: 1)
    }

    func hide(){
        wdg.hide()
    }

    func show(){
        wdg.showAll()
    }
}

let status = Application.run(startupHandler: { app in
    app.addAction(entries: &appActionEntries, nEntries: appActionEntries.count, userData: app.ptr)
}, activationHandler: { app in
    window = ApplicationWindow(application: app)
    hd = HeaderBar()
    hd.title = "Muscalc"
    hd.showCloseButton = true
    window.set(titlebar: hd)
    window.setDefaultSize(width: 640, height: 360)

    b_back = Button(label: "←  Back")
    b_back.sensitive = false
    b_back.connect(signal: ButtonSignalName.clicked, handler: {
        b_back.sensitive = false
        entry_page.show()
        result_page.hide()
    })
    hd.add(b_back)


    entry_page = EntryPage()
    entry_page.on_calc {
        b_back.sensitive = true
        entry_page.hide()
        result_page.show()
    }

    result_page = ResultPage()

    window.add(entry_page.wdg)
    window.showAll()
})

withExtendedLifetime([window as Any, store as Any, hd as Any, entry_page as Any,
                    result_page as Any, b_back as Any]) {
    guard let status = status else {
        fatalError("Could not create Application")
    }
    guard status == 0 else {
        fatalError("Application exited with status \(status)")
    }
}
