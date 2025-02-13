/**
 * @name         : ImportCSVDataValueIConverter
 * @author       : Nigam Goyal
 * @date         : 12-08-2022
 * @description  : For manage the different datatype in object
 * @test classes : ImportCSVDataControllerTest
 **/
public interface ImportCSVDataValueIConverter { 
    Object getValue(String strInputValue);
}