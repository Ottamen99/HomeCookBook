import XCTest

final class EditRecipeViewUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        // Add launch arguments/environment variables if needed for test setup
        // For example, to ensure sample data is loaded or to reset state.
        // app.launchArguments += ["-UITesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    func testLoadExistingRecipeData() throws {
        // Navigation steps:
        // 1. Find and tap the "Sample Recipe" row.
        //    (Assuming it's a StaticText in a List/ScrollView)
        //    Accessibility identifier for the recipe list itself might be needed.
        //    Let's assume the recipe name "Sample Recipe" is unique enough for now.
        //    If RecipeRowView has an identifier like "recipeRow_Sample Recipe", use that.
        //    For now, find by text.
        app.staticTexts["Sample Recipe"].firstMatch.tap()

        // 2. On RecipeDetailView, find and tap the "Edit" button.
        //    (Assuming identifier: "recipeDetail_edit_button")
        //    This identifier needs to be present in RecipeDetailView.swift
        app.buttons["recipeDetail_edit_button"].tap()

        // Now on EditRecipeView:
        // Verify data is loaded correctly
        XCTAssertEqual(app.textFields["editRecipe_name_textfield"].value as? String, "Sample Recipe")
        // Description might be trickier if it's a TextEditor, value might not be directly accessible.
        // Check for existence and some properties.
        XCTAssertTrue(app.textViews["editRecipe_description_texteditor"].exists)
        // For TextEditor, we might need to tap and type to verify, or check its displayed text if possible.
        // For now, let's assume its initial text is part of its accessibility value or can be checked.
        // This often requires the TextEditor's content to be mirrored to its accessibilityValue.

        // Verify time (e.g., "30m" for 30 minutes)
        XCTAssertEqual(app.staticTexts["editRecipe_time_text"].label, "30m")
        // Verify servings (e.g., "4")
        XCTAssertEqual(app.staticTexts["editRecipe_servings_text"].label, "4")
        // Verify difficulty (e.g., "Easy") - this depends on how DifficultyPill is implemented.
        // If DifficultyPill has an identifier and its label is the difficulty string:
        // XCTAssertEqual(app.staticTexts["editRecipe_difficulty_menu"].label, "Easy") // The menu label itself
        // A better way for Menu is to check the currently selected option's label within the menu button itself.
        // The menu's label itself might not be the displayed value.
        // Assuming the Menu's label (what's visible before tapping) contains the difficulty text.
        // This might need to be `app.buttons["editRecipe_difficulty_menu"].label` if it's a button showing the current value.
        // Or, if the DifficultyPill is a distinct element:
        XCTAssertTrue(app.buttons["editRecipe_difficulty_menu"].staticTexts["Easy"].exists || app.staticTexts["Easy"].exists, "Difficulty 'Easy' not found in the menu's current display.")


    }

    func testEditRecipeNameAndSave() throws {
        app.staticTexts["Sample Recipe"].firstMatch.tap()
        app.buttons["recipeDetail_edit_button"].tap()

        let nameTextField = app.textFields["editRecipe_name_textfield"]
        XCTAssertTrue(nameTextField.exists, "Name text field not found")

        // Clear existing text and type new name
        nameTextField.tap()

        // Standard way to clear text: select all and replace
        // Check if text field has value, if so, select all and delete
        if let currentValue = nameTextField.value as? String, !currentValue.isEmpty {
            // Create a gesture to triple tap for selecting all text
            nameTextField.press(forDuration: 0.1) // Ensure it's focused
            // Some systems might need a different tap count or method
            // A common pattern is to tap, then select all from the menu
            nameTextField.tap() // Ensure focus
            // Check if "Select All" menu item appears
            if app.menuItems["Select All"].exists {
                app.menuItems["Select All"].tap()
                app.keys["delete"].tap() // then delete
            } else {
                // Fallback: manually delete characters if "Select All" is not available
                // This is less reliable and might need adjustment based on max expected length
                let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
                nameTextField.typeText(deleteString)
            }
        }


        let newRecipeName = "Updated Sample Recipe"
        nameTextField.typeText(newRecipeName)

        // Tap description to dismiss keyboard if it's obscuring save.
        // Or use the keyboard done button if available and necessary.
        if app.keyboards.keys["Done"].exists {
            app.keyboards.buttons["Done"].tap()
        } else {
            // Fallback: tap another element to dismiss keyboard
            app.staticTexts["Description"].firstMatch.tap() // Assuming "Description" label exists near TextEditor
        }


        app.buttons["editRecipe_save_button"].tap()

        // After saving, app should navigate back to RecipeDetailView.
        // Verify the new name is displayed there.
        // This assumes RecipeDetailView's title or a text field reflects the recipe name.
        // If RecipeDetailView's navigation title is the recipe name:
        XCTAssertTrue(app.navigationBars[newRecipeName].waitForExistence(timeout: 3), "Navigation title did not update to new recipe name.")
        // Or, if there's a static text with the name:
        // XCTAssertTrue(app.staticTexts[newRecipeName].waitForExistence(timeout: 2))
    }

    func testAddIngredientToRecipe() throws {
        app.staticTexts["Sample Recipe"].firstMatch.tap()
        app.buttons["recipeDetail_edit_button"].tap()

        // Assume "Sample Recipe" initially has 1 ingredient.
        let initialIngredientCount = app.collectionViews.cells.matching(identifier: #"editRecipe_ingredientRow_.*"#).count

        // Tap "Add More Ingredients"
        // Check if the empty state button exists first
        let addEmptyButton = app.buttons["editRecipe_addIngredients_empty_button"]
        let addMoreButton = app.buttons["editRecipe_addMoreIngredients_button"]

        if addEmptyButton.exists {
            addEmptyButton.tap()
        } else {
            addMoreButton.tap()
        }

        // In IngredientSelectionView (Simplified)
        // These identifiers/texts need to exist in IngredientSelectionView
        // Wait for "Flour" to appear, it might be in a list that loads.
        let flourText = app.staticTexts["Flour"]
        XCTAssertTrue(flourText.waitForExistence(timeout: 2), "Flour option not found in IngredientSelectionView")
        flourText.tap()

        // Assuming a "Done" button in IngredientSelectionView confirms selection.
        // This identifier needs to be confirmed.
        let doneButtonInSheet = app.buttons["ingredientSelection_done_button"] // Or "Done" if generic
        if !doneButtonInSheet.exists {
             XCTFail("Confirmation button like 'ingredientSelection_done_button' or 'Done' not found in IngredientSelectionView sheet.")
        }
        doneButtonInSheet.tap()

        // Back in EditRecipeView
        // Verify a new ingredient row for "Flour" exists.
        // The new ingredient will be at index `initialIngredientCount`.
        let newIngredientIndex = initialIngredientCount

        let newFlourRow = app.collectionViews.cells.containing(.staticText, identifier:"Flour").firstMatch
        // A more direct way if staticTexts["Flour"] is within the row
        XCTAssertTrue(app.staticTexts["Flour"].waitForExistence(timeout: 2), "Flour staticText not found in an ingredient row after adding.")


        let quantityFieldPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "editRecipe_ingredientQuantity_textfield_")
        let quantityField = app.textFields.matching(quantityFieldPredicate).element(boundBy: newIngredientIndex)
        XCTAssertTrue(quantityField.waitForExistence(timeout: 1), "Quantity field for new ingredient not found.")
        quantityField.tap()
        // Clear text field - this part is tricky and might need adjustment
        if let currentValue = quantityField.value as? String, !currentValue.isEmpty {
            quantityField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count))
        }
        quantityField.typeText("100")

        let unitPickerPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "editRecipe_ingredientUnit_picker_")
        let unitPicker = app.buttons.matching(unitPickerPredicate).element(boundBy: newIngredientIndex) // Pickers can be buttons
        XCTAssertTrue(unitPicker.waitForExistence(timeout: 1), "Unit picker for new ingredient not found.")
        unitPicker.tap()

        // Assuming UnitOfMeasure.grams.displayName is "grams" and it's a button in a menu
        let gramsButton = app.buttons["grams"]
        XCTAssertTrue(gramsButton.waitForExistence(timeout: 1), "Grams option in picker not found.")
        gramsButton.tap()

        // Dismiss keyboard if it's showing, to ensure Save button is hittable
        if app.keyboards.exists {
            if app.buttons["Done"].exists { // Standard keyboard Done
                 app.buttons["Done"].tap()
            } else { // Toolbar Done
                app.buttons["editRecipe_keyboardDone_button"].tap()
            }
        }

        app.buttons["editRecipe_save_button"].tap()

        // Optional: Verify on RecipeDetailView that "Flour" is listed.
        // This requires RecipeDetailView to display ingredients and "Flour" to be identifiable.
        app.buttons["recipeDetail_edit_button"].waitForExistence(timeout: 2) // Wait to return to detail view
        XCTAssertTrue(app.staticTexts["Flour"].exists, "Flour not found on RecipeDetailView after saving.")
    }

    func testEditIngredientQuantityInRecipe() throws {
        app.staticTexts["Sample Recipe"].firstMatch.tap()
        app.buttons["recipeDetail_edit_button"].tap()

        // Assume "Sample Ingredient" is the first ingredient (index 0).
        let quantityFieldPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "editRecipe_ingredientQuantity_textfield_")
        let quantityField = app.textFields.matching(quantityFieldPredicate).element(boundBy: 0)

        XCTAssertTrue(quantityField.waitForExistence(timeout: 1), "Quantity field for first ingredient not found.")
        quantityField.tap()

        // Clear existing text and type new quantity
        if let currentValue = quantityField.value as? String, !currentValue.isEmpty {
             // A common way to clear: select all then delete. This might need adjustment.
            if app.menuItems["Select All"].exists {
                app.menuItems["Select All"].tap()
                app.keys["delete"].tap()
            } else {
                quantityField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count))
            }
        }
        quantityField.typeText("200")

        // Dismiss keyboard
        if app.keyboards.exists {
            if app.buttons["Done"].exists {
                 app.buttons["Done"].tap()
            } else {
                app.buttons["editRecipe_keyboardDone_button"].tap()
            }
        }

        app.buttons["editRecipe_save_button"].tap()

        // Optional: Verify on RecipeDetailView the updated quantity.
        // This would require the detail view to show quantities and for "Sample Ingredient"
        // to be identifiable along with its quantity.
        // For now, we'll assume the save completes and returns to detail view.
        XCTAssertTrue(app.buttons["recipeDetail_edit_button"].waitForExistence(timeout: 2), "Failed to return to Recipe Detail View after saving quantity.")
        // To verify the change, one might tap edit again and check the value,
        // or have more detailed accessibility on RecipeDetailView.
        app.buttons["recipeDetail_edit_button"].tap() // Go back to edit mode
        XCTAssertEqual(quantityField.value as? String, "200", "Quantity was not updated correctly after save.")

    }

    func testDeleteIngredientFromRecipe() throws {
        // First, ensure there are at least two ingredients. Add "Flour" for this test.
        // Simplified setup from testAddIngredientToRecipe
        app.staticTexts["Sample Recipe"].firstMatch.tap()
        app.buttons["recipeDetail_edit_button"].tap()

        let addEmptyButton = app.buttons["editRecipe_addIngredients_empty_button"]
        let addMoreButton = app.buttons["editRecipe_addMoreIngredients_button"]
        if addEmptyButton.exists { addEmptyButton.tap() } else { addMoreButton.tap() }
        XCTAssertTrue(app.staticTexts["Flour"].waitForExistence(timeout: 2))
        app.staticTexts["Flour"].tap()
        let doneButtonInSheet = app.buttons["ingredientSelection_done_button"] // Or "Done"
        if !doneButtonInSheet.exists { XCTFail("Done button in sheet not found") }
        doneButtonInSheet.tap()
        // At this point, "Flour" should be added. Let's assume it's the second ingredient row.
        // The original "Sample Ingredient" is first.

        // Now, delete "Flour" (the second ingredient).
        // Find the row containing "Flour".
        let flourRowIdentifier = app.staticTexts["Flour"].firstMatch // This is the text, not the row itself.
        // We need to find the specific row. Assuming it's a cell in a collection view/list.
        // The identifier `editRecipe_ingredientRow_.*` is on the HStack.
        // Let's target the row that contains the staticText "Flour".

        // If "Flour" is the text in the second row:
        let rowPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "editRecipe_ingredientRow_")
        let ingredientRows = app.descendants(matching: .any).matching(rowPredicate)

        // This assumes "Flour" is present and makes its row the one to target.
        // This is a bit indirect. A direct identifier on the row containing "Flour" text would be better.
        // For now, let's assume "Flour" makes the second row identifiable for swipe.
        // If "Sample Ingredient" is first, "Flour" is second.
        // We need to swipe the specific cell.

        let flourCell = app.collectionViews.cells.containing(.staticText, identifier:"Flour").firstMatch
        // Or if it's not a collection view, but just elements laid out:
        // let flourCell = app.otherElements.containing(.staticText, identifier:"Flour").firstMatch
        // This might be tricky. A more stable way is if the row itself has an ID like "editRecipe_ingredientRow_FLOUR_ID"
        // For now, let's assume the second row (index 1) is Flour.
        let targetRow = ingredientRows.element(boundBy: 1)

        XCTAssertTrue(targetRow.waitForExistence(timeout: 2), "Row for 'Flour' not found for deletion.")
        targetRow.swipeLeft()

        // Tap the "Delete" button that appears after swipe.
        // This delete button is provided by the swipe action, not one we defined with an identifier.
        app.buttons["Delete"].firstMatch.tap() // This is a system button.

        // Verify "Flour" is no longer visible.
        XCTAssertFalse(app.staticTexts["Flour"].exists, "'Flour' should no longer exist after deletion.")

        // Dismiss keyboard if it's showing
        if app.keyboards.exists {
            if app.buttons["Done"].exists {
                 app.buttons["Done"].tap()
            } else {
                app.buttons["editRecipe_keyboardDone_button"].tap()
            }
        }

        app.buttons["editRecipe_save_button"].tap()

        // Optional: Verify on RecipeDetailView that "Flour" is gone.
        XCTAssertTrue(app.buttons["recipeDetail_edit_button"].waitForExistence(timeout: 2), "Failed to return to Recipe Detail View after deleting ingredient.")
        XCTAssertFalse(app.staticTexts["Flour"].exists, "Flour should not be found on RecipeDetailView after deletion and save.")
    }

    // MARK: - Step Management Tests

    func testAddStepToRecipe() throws {
        app.staticTexts["Sample Recipe"].firstMatch.tap()
        app.buttons["recipeDetail_edit_button"].tap()

        // Tap "Add preparation steps" or "Add More Steps"
        let addEmptyButton = app.buttons["editRecipe_addSteps_empty_button"]
        let addMoreButton = app.buttons["editRecipe_addMoreSteps_button"]

        if addEmptyButton.exists {
            addEmptyButton.tap()
        } else {
            // If there are existing steps, the "add more" button might not exist if list is full,
            // but for adding the first few, one of these should be present.
            XCTAssertTrue(addMoreButton.exists, "Neither 'Add Steps' button found.")
            addMoreButton.tap()
        }

        // In StepFormView
        let instructionsTextView = app.textViews["stepForm_instructions_textview"]
        XCTAssertTrue(instructionsTextView.waitForExistence(timeout: 1), "Instructions text view in StepFormView not found.")
        instructionsTextView.tap()
        instructionsTextView.typeText("New test step instructions.")

        let saveStepButton = app.buttons["stepForm_save_button"]
        XCTAssertTrue(saveStepButton.exists, "Save button in StepFormView not found.")
        saveStepButton.tap()

        // Back in EditRecipeView
        XCTAssertTrue(app.staticTexts["New test step instructions."].waitForExistence(timeout: 1), "New step instructions not found in EditRecipeView.")

        app.buttons["editRecipe_save_button"].tap()

        // Optional: Verify on RecipeDetailView
        XCTAssertTrue(app.buttons["recipeDetail_edit_button"].waitForExistence(timeout: 2), "Failed to return to Recipe Detail View after saving step.")
        XCTAssertTrue(app.staticTexts["New test step instructions."].exists, "New step not found on RecipeDetailView after saving.")
    }

    func testEditStepInRecipe() throws {
        app.staticTexts["Sample Recipe"].firstMatch.tap()
        app.buttons["recipeDetail_edit_button"].tap()

        // Add an initial step to edit
        let initialStepText = "Original step instructions."
        let addEmptyButton = app.buttons["editRecipe_addSteps_empty_button"]
        let addMoreButton = app.buttons["editRecipe_addMoreSteps_button"]
        if addEmptyButton.exists { addEmptyButton.tap() } else { addMoreButton.tap() }

        let instructionsTextView = app.textViews["stepForm_instructions_textview"]
        XCTAssertTrue(instructionsTextView.waitForExistence(timeout: 1))
        instructionsTextView.tap()
        instructionsTextView.typeText(initialStepText)
        app.buttons["stepForm_save_button"].tap()

        XCTAssertTrue(app.staticTexts[initialStepText].waitForExistence(timeout: 1), "Initial step not found in EditRecipeView.")

        // Tap the step row to edit it. Assuming it's the first one.
        // The step row itself is a button with identifier "editRecipe_stepRow_..."
        let stepRowPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "editRecipe_stepRow_")
        let firstStepRowButton = app.buttons.matching(stepRowPredicate).element(boundBy: 0)
        XCTAssertTrue(firstStepRowButton.waitForExistence(timeout: 1), "First step row button not found.")
        firstStepRowButton.tap()

        // In StepFormView (for editing)
        XCTAssertTrue(instructionsTextView.waitForExistence(timeout: 1), "Instructions text view for editing not found.")
        instructionsTextView.tap() // Focus
        // To append text, we might need to tap at the end or just type.
        // XCUI's typeText usually appends unless cleared.
        instructionsTextView.typeText(" Updated.")

        app.buttons["stepForm_save_button"].tap()

        // Back in EditRecipeView
        let updatedStepText = initialStepText + " Updated."
        XCTAssertTrue(app.staticTexts[updatedStepText].waitForExistence(timeout: 1), "Updated step instructions not found in EditRecipeView.")

        // Dismiss keyboard if it's showing
        if app.keyboards.exists {
            if app.buttons["Done"].exists { app.buttons["Done"].tap() }
            else { app.buttons["editRecipe_keyboardDone_button"].tap() }
        }

        app.buttons["editRecipe_save_button"].tap()

        // Optional: Verify on RecipeDetailView
        XCTAssertTrue(app.buttons["recipeDetail_edit_button"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts[updatedStepText].exists, "Updated step not found on RecipeDetailView after saving.")
    }

    func testDeleteStepFromRecipe() throws {
        app.staticTexts["Sample Recipe"].firstMatch.tap()
        app.buttons["recipeDetail_edit_button"].tap()

        let stepTextToDelete = "Step to be deleted."
        let stepTextToKeep = "Another step."

        // Add step to be deleted
        let addEmptyButton = app.buttons["editRecipe_addSteps_empty_button"]
        var addMoreButton = app.buttons["editRecipe_addMoreSteps_button"] // re-evaluate after first add
        if addEmptyButton.exists { addEmptyButton.tap() } else { addMoreButton.tap() }
        var instructionsTextView = app.textViews["stepForm_instructions_textview"] // re-evaluate
        XCTAssertTrue(instructionsTextView.waitForExistence(timeout: 1))
        instructionsTextView.tap()
        instructionsTextView.typeText(stepTextToDelete)
        app.buttons["stepForm_save_button"].tap()
        XCTAssertTrue(app.staticTexts[stepTextToDelete].waitForExistence(timeout: 1))

        // Add another step to keep
        addMoreButton = app.buttons["editRecipe_addMoreSteps_button"] // Re-query, as UI might have changed
        XCTAssertTrue(addMoreButton.exists, "'Add More Steps' button not found for adding second step.")
        addMoreButton.tap()
        instructionsTextView = app.textViews["stepForm_instructions_textview"] // Re-query
        XCTAssertTrue(instructionsTextView.waitForExistence(timeout: 1))
        instructionsTextView.tap()
        instructionsTextView.typeText(stepTextToKeep)
        app.buttons["stepForm_save_button"].tap()
        XCTAssertTrue(app.staticTexts[stepTextToKeep].waitForExistence(timeout: 1))


        // Find the row for "Step to be deleted."
        // This assumes the step text is directly available for swipe.
        // A more robust way might be to find the button with the specific ID.
        // For this test, we'll assume the text itself is part of the swipeable element or its container.
        // The button containing this text is the one with identifier "editRecipe_stepRow_..."

        let stepRowsPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "editRecipe_stepRow_")
        let allStepRowButtons = app.buttons.matching(stepRowsPredicate)

        // Find the specific row button that contains the text "Step to be deleted."
        var rowToDelete: XCUIElement?
        for i in 0..<allStepRowButtons.count {
            let button = allStepRowButtons.element(boundBy: i)
            if button.staticTexts[stepTextToDelete].exists {
                rowToDelete = button
                break
            }
        }

        guard let targetRow = rowToDelete, targetRow.exists else {
            XCTFail("Row for 'Step to be deleted.' not found.")
            return
        }

        targetRow.swipeLeft()
        app.buttons["Delete"].firstMatch.tap() // System delete button

        XCTAssertFalse(app.staticTexts[stepTextToDelete].exists, "'Step to be deleted.' should no longer exist.")
        XCTAssertTrue(app.staticTexts[stepTextToKeep].exists, "'Another step.' should still exist.")

        // Dismiss keyboard if it's showing
        if app.keyboards.exists {
            if app.buttons["Done"].exists { app.buttons["Done"].tap() }
            else { app.buttons["editRecipe_keyboardDone_button"].tap() }
        }

        app.buttons["editRecipe_save_button"].tap()

        XCTAssertTrue(app.buttons["recipeDetail_edit_button"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts[stepTextToDelete].exists)
        XCTAssertTrue(app.staticTexts[stepTextToKeep].exists)
    }
}
```
